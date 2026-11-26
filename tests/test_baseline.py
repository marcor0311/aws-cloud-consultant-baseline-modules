import copy
import json
import unittest
from decimal import Decimal

import boto3
from botocore.stub import Stubber

from scripts.baseline import REPOSITORY, ROOT, catalog, estimate, shopping_list, shopping_list_markdown, tier_cost
from scripts.quote_aws import quote


class BaselineSelectionTest(unittest.TestCase):
    def setUp(self):
        samples = ROOT / "examples" / "baseline-agent"
        self.request = json.loads((samples / "usage.json").read_text())
        self.rates = json.loads((samples / "rates.us-east-1.json").read_text())
        self.modules = catalog()

    def test_catalog_and_architect_selection(self):
        pilot_modules = {
            "s3": {"default", "retention"},
            "dynamodb": {"on-demand", "provisioned"},
            "api-gateway": {"iam", "jwt"},
        }
        for name, profiles in pilot_modules.items():
            module = self.modules[name]
            self.assertTrue(profiles <= module["profiles"].keys())
            self.assertEqual(module["audit"]["production_approval"], module["review"]["production"])
            self.assertEqual([], module["missing_files"])
            self.assertTrue(module["consumer"]["required_inputs"])
        committed = catalog("HEAD")
        self.assertIn(f"?ref={committed['s3']['commit']}", committed["s3"]["source"])

        result = estimate(self.request, self.rates, self.modules)
        self.assertEqual(["13.83", "12.91", "16.46", "13.83"], [s["monthly_total"] for s in result["scenarios"]])
        for scenario in result["scenarios"]:
            self.assertEqual("estimated", scenario["status"])
            keys = [line for group in scenario["groups"] for line in group["lines"] if line["meter"] == "kms-keys"]
            self.assertEqual(1, len(keys))
            self.assertEqual(2, keys[0]["quantity"])

    def test_partial_result_and_explicit_zero(self):
        scenario = self.request["scenarios"][0]
        del scenario["shared_usage"]["lambda-requests"]
        del self.rates["rates"]["logs-ingest"]
        self.rates["rates"].pop("internet-egress")
        scenario["shared_usage"]["internet-egress"] = 0

        result = estimate(self.request, self.rates, self.modules)["scenarios"][0]
        self.assertEqual("partial", result["status"])
        self.assertIsNone(result["monthly_total"])
        self.assertEqual("11.33", result["known_monthly_cost"])
        missing = {line["meter"]: line["pending"] for group in result["groups"] for line in group["lines"] if line["pending"]}
        self.assertEqual({"lambda-requests": "uso pendiente", "logs-ingest": "tarifa pendiente"}, missing)

    def test_shopping_list_preview_and_published_selection(self):
        base = self.request["scenarios"][0]
        base["modules"][0]["configuration"] = {"bucket_name": "example-application"}
        self.request["source_issue"] = "https://github.com/example/project/issues/3"
        self.request["gaps"] = ["Distribución CDN"]
        self.request["scenarios"] = [base]
        draft_list = shopping_list(self.request, self.rates, self.modules)
        option = draft_list["scenarios"][0]["options"][0]
        self.assertIsNone(option["selection"])
        self.assertIn("bucket_name", option["required_inputs"])
        rendered = shopping_list_markdown(draft_list)
        self.assertIn("Total estimado 13.83", rendered)
        self.assertIn("Distribución CDN", rendered)
        self.assertIn("árbol de trabajo", rendered)

        commit = "a" * 40
        module = self.modules["s3"]
        module.update(commit=commit, published_in_origin=True)
        module["review"]["production"] = "pending"
        published_list = shopping_list(self.request, self.rates, self.modules)
        self.assertEqual({
            "module_id": "s3", "repository": REPOSITORY, "commit": commit,
            "candidate_version": module["candidate_version"], "approval_status": "draft",
            "profile": "default", "configuration": {"bucket_name": "example-application"},
        }, published_list["scenarios"][0]["options"][0]["selection"])
        module["review"]["production"] = "approved"
        unverified = shopping_list(self.request, self.rates, self.modules)["scenarios"][0]["options"][0]
        self.assertIsNone(unverified["selection"])
        self.assertIn("verificar aprobación del arquitecto para el commit exacto", unverified["selection_pending"])

    def test_tiers_and_duplicate_usage(self):
        rate = self.rates["rates"]["s3-standard-storage"]
        self.assertEqual(Decimal("1199.60"), tier_cost(Decimal("52200"), rate["tiers"], "s3-standard-storage"))
        scenario = self.request["scenarios"][0]
        scenario["modules"][0]["usage"]["kms-keys"] = 1
        with self.assertRaisesRegex(ValueError, "una sola vez"):
            estimate(self.request, self.rates, self.modules)
        scenario["modules"].append(copy.deepcopy(scenario["modules"][0]))
        with self.assertRaisesRegex(ValueError, "un solo perfil"):
            estimate(self.request, self.rates, self.modules)

    def test_price_list_sdk_selection(self):
        product = {
            "product": {"sku": "TABLE", "attributes": {"regionCode": "us-east-1"}},
            "publicationDate": "2026-11-25T15:02:09Z",
            "terms": {"OnDemand": {"term": {
                "effectiveDate": "2026-01-01T00:00:00Z",
                "priceDimensions": {
                    "free": {"unit": "GB-Mo", "beginRange": "0", "endRange": "25", "pricePerUnit": {"USD": "0"}},
                    "paid": {"unit": "GB-Mo", "beginRange": "25", "endRange": "Inf", "pricePerUnit": {"USD": "0.25"}},
                },
            }}},
        }
        request = {"region": "us-east-1", "currency": "USD", "rates": {
            "table-storage": {"service": "AmazonDynamoDB", "sku": "TABLE", "exclude_free_allowance": True},
        }}
        client = boto3.client(
            "pricing", region_name="us-east-1", aws_access_key_id="test", aws_secret_access_key="test",
        )
        with Stubber(client) as pricing:
            pricing.add_response("get_products", {"PriceList": [json.dumps(product)]}, {
                "ServiceCode": "AmazonDynamoDB",
                "Filters": [{"Type": "TERM_MATCH", "Field": "sku", "Value": "TABLE"}],
            })
            result = quote(request, client=client)
            pricing.assert_no_pending_responses()
        self.assertEqual([{"start": "0", "end": "Inf", "price": "0.25"}], result["rates"]["table-storage"]["tiers"])
