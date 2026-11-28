import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path


SPEC = importlib.util.spec_from_file_location(
    "select_emulator_cases", Path(__file__).resolve().parents[1] / "scripts/select_emulator_cases.py"
)
selector = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(selector)


class EmulatorCaseSelectionTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.git("init", "-q")
        self.git("config", "user.name", "Fixture")
        self.git("config", "user.email", "fixture@example.test")
        self.add_module("s3", "default")
        self.add_module("dynamodb", "on-demand")
        self.add_module("existing", "default")
        self.base = self.commit()

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.root), *args], text=True).strip()

    def write(self, path, text=""):
        path = self.root / path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def add_module(self, name, profile):
        self.write(f"aws/{name}/module.yaml")
        self.write(f"aws/{name}/main.tf")
        self.write(f"aws/{name}/examples/{profile}/main.tf", 'module "baseline" { source = "../.." }')

    def commit(self):
        self.git("add", "-A")
        self.git("commit", "-qm", "Fixture")
        return self.git("rev-parse", "HEAD")

    def selected(self):
        self.commit()
        return selector.select(self.root, selector.git_changes(self.root, self.base))

    def test_added_module_picks_profiles(self):
        self.add_module("sqs", "standard")
        self.assertEqual(self.selected()["cases"], ["sqs/standard"])

    def test_modified_module_includes_direct_examples(self):
        self.write("aws/s3/main.tf", "# Terraform change")
        self.write(
            "examples/consumer/main.tf",
            'module "bucket" { source = "../../aws/s3" }',
        )
        result = self.selected()
        self.assertEqual(result["cases"], ["example:examples/consumer", "s3/default"])
        self.assertEqual(result["modules"], ["s3"])

    def test_retirement_rejects_live_usage(self):
        self.write("examples/consumer/main.tf", 'module "old" { source = "../../aws/existing" }')
        self.base = self.commit()
        self.git("rm", "-qr", "aws/existing")
        with self.assertRaisesRegex(ValueError, "Referencias activas"):
            self.selected()

    def test_retirement_selects_only_a_surviving_updated_consumer(self):
        self.write("examples/consumer/main.tf", 'module "old" { source = "../../aws/existing" }')
        self.base = self.commit()
        self.git("rm", "-qr", "aws/existing")
        self.write("examples/consumer/main.tf", 'module "new" { source = "../../aws/s3" }')
        result = self.selected()
        self.assertEqual(result["retired"], ["existing"])
        self.assertEqual(result["cases"], ["example:examples/consumer"])
        self.assertEqual(result["modules"], [])

    def test_documentation_has_no_cases(self):
        self.write("docs/example.md", "Documentation")
        self.write("aws/s3/README.md", "Documentation")
        self.assertEqual(self.selected()["cases"], [])

    def test_shared_validation_change_picks_representative_cases(self):
        self.write("scripts/validate.sh")
        self.assertEqual(self.selected()["cases"], ["dynamodb/on-demand", "s3/default"])

    def test_manual_inventory_tests_all_profiles(self):
        self.assertEqual(
            selector.select(self.root, [], full=True)["cases"],
            ["dynamodb/on-demand", "existing/default", "s3/default"],
        )


if __name__ == "__main__":
    unittest.main()
