#!/usr/bin/env python3
"""Normalize AWS Price List products for the baseline estimator."""

import argparse
import json
import re
import sys
from datetime import date
from decimal import Decimal, InvalidOperation
from pathlib import Path
from urllib.request import urlopen


BULK_URL = "https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws"
QUERY_URL = "https://docs.aws.amazon.com/aws-cost-management/latest/APIReference/API_pricing_GetProducts.html"


def normalize(selector, product, terms, currency, region):
    attributes = product["attributes"]
    if region not in (attributes.get("regionCode"), attributes.get("fromRegionCode")):
        raise ValueError(f"El SKU {selector['sku']} no corresponde a {region}.")
    if len(terms) != 1:
        raise ValueError(f"El SKU {selector['sku']} necesita exactamente un término OnDemand.")
    term = next(iter(terms.values()))
    dimensions = sorted(term["priceDimensions"].values(), key=lambda line: Decimal(line["beginRange"]))
    units = {line["unit"] for line in dimensions}
    if len(units) != 1 or any(line.get("appliesTo") for line in dimensions):
        raise ValueError(f"Dimensiones de cobro ambiguas para el SKU {selector['sku']}.")

    allowance = Decimal(0)
    if selector.get("exclude_free_allowance"):
        while dimensions and Decimal(dimensions[0]["pricePerUnit"][currency]) == 0:
            allowance = Decimal(dimensions.pop(0)["endRange"])
        if not dimensions or not allowance.is_finite():
            raise ValueError(f"El SKU {selector['sku']} requiere al menos un tramo pagado.")

    return {
        **selector,
        "unit": units.pop(),
        "aws_usage_type": attributes.get("usagetype"),
        "aws_operation": attributes.get("operation"),
        "effective_on": term["effectiveDate"],
        "tiers": [
            {
                "start": str(Decimal(line["beginRange"]) - allowance),
                "end": line["endRange"] if line["endRange"] == "Inf" else str(Decimal(line["endRange"]) - allowance),
                "price": line["pricePerUnit"][currency],
            }
            for line in dimensions
        ],
    }


def public_price_lists(selectors, region, local_directory=None):
    for service in sorted({item["service"] for item in selectors.values()}):
        if not re.fullmatch(r"[A-Za-z0-9-]+", service):
            raise ValueError(f"Código de servicio no válido: {service}.")
        if local_directory:
            yield service, json.loads((local_directory / f"{service}.json").read_text())
        else:
            with urlopen(f"{BULK_URL}/{service}/current/{region}/index.json", timeout=45) as response:
                yield service, json.load(response)


def quote(request, client=None, local_directory=None):
    region, currency = request["region"], request["currency"]
    if not re.fullmatch(r"[a-z]{2}(?:-[a-z]+)+-\d+", region):
        raise ValueError(f"Región AWS no válida: {region}.")
    selectors = request["rates"]
    catalogs = {} if client else dict(public_price_lists(selectors, region, local_directory))
    rates = {}
    for meter, original in selectors.items():
        selector = {field: original[field] for field in ("service", "sku", "exclude_free_allowance") if field in original}
        service, sku = selector["service"], selector["sku"]
        if client:
            response = client.get_products(
                ServiceCode=service, Filters=[{"Type": "TERM_MATCH", "Field": "sku", "Value": sku}],
            )
            if len(response["PriceList"]) != 1 or response.get("NextToken"):
                raise ValueError(f"La consulta de {service}/{sku} no devolvió un único producto.")
            item = json.loads(response["PriceList"][0])
            product, terms, source = item["product"], item["terms"]["OnDemand"], QUERY_URL
        else:
            item = catalogs[service]
            if item["offerCode"] != service:
                raise ValueError(f"El archivo regional no corresponde a {service}.")
            product, terms = item["products"][sku], item["terms"]["OnDemand"][sku]
            source = f"{BULK_URL}/{service}/{item['version']}/{region}/index.json"
        if product["sku"] != sku:
            raise ValueError(f"AWS devolvió un SKU distinto del solicitado para {meter}.")
        rates[meter] = {
            **normalize(selector, product, terms, currency, region),
            "source": source,
            "published_on": item["publicationDate"],
        }
    return {"region": region, "currency": currency, "quoted_on": date.today().isoformat(), "rates": rates}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("selectors", type=Path, help="JSON con región, moneda y servicio/SKU por dimensión")
    source = parser.add_mutually_exclusive_group()
    source.add_argument("--local-price-lists", type=Path, help="Archivos regionales locales por código de servicio")
    source.add_argument("--sdk", action="store_true", help="Consultar GetProducts usando boto3 y el perfil de AWS")
    args = parser.parse_args()
    try:
        selectors = json.loads(args.selectors.read_text())
        if args.sdk:
            import boto3
            from botocore.exceptions import BotoCoreError, ClientError

            try:
                data = quote(selectors, client=boto3.client("pricing", region_name="us-east-1"))
            except (BotoCoreError, ClientError) as error:
                raise ValueError(f"AWS Price List GetProducts: {error}") from error
        else:
            data = quote(selectors, local_directory=args.local_price_lists)
    except (OSError, ValueError, KeyError, TypeError, InvalidOperation, ImportError) as error:
        parser.exit(2, f"No se pudieron cotizar los SKUs de AWS: {error}\n")
    json.dump(data, sys.stdout, ensure_ascii=False, indent=2)
    print()


if __name__ == "__main__":
    main()
