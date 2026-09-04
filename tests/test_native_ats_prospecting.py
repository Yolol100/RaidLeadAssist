import importlib.util
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "native_ats_prospecting.py"
spec = importlib.util.spec_from_file_location("native_ats_prospecting", SCRIPT)
assert spec and spec.loader
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)


class NativeAtsProspectingTests(unittest.TestCase):
    def test_source_requires_identity_and_website(self):
        with self.assertRaises(ValueError):
            module.SourceSpec.from_dict({"provider": "greenhouse", "account": "x"})

    def test_unsupported_provider_is_rejected(self):
        with self.assertRaises(ValueError):
            module.SourceSpec.from_dict({
                "provider": "unknown",
                "account": "x",
                "company_name": "Example",
                "company_website": "https://example.com",
            })

    def test_domain_normalization(self):
        self.assertEqual(module.canonical_website("http://WWW.Example.com/path"), "https://example.com/")
        self.assertEqual(module.domain_key("https://www.example.com/a"), "example.com")

    def test_numeric_timestamp_normalization(self):
        self.assertEqual(module.normalize_date(1788264000000), "2026-09-01T12:00:00Z")

    @patch.object(module, "get_json")
    def test_greenhouse_mapping(self, get_json):
        get_json.return_value = {
            "jobs": [{
                "title": "WordPress Developer",
                "absolute_url": "https://job-boards.greenhouse.io/example/jobs/1",
                "updated_at": "2026-09-01T12:00:00Z",
                "location": {"name": "Remote"},
            }]
        }
        source = module.SourceSpec("greenhouse", "example", "Example", "https://example.com", "NL")
        jobs = module.fetch_greenhouse(source, 10)
        self.assertEqual(len(jobs), 1)
        self.assertEqual(jobs[0].title, "WordPress Developer")
        self.assertEqual(jobs[0].location, "Remote")

    def test_aggregate_deduplicates_company_domain(self):
        signals = [
            module.JobSignal("lever", "Example", "https://www.example.com", "NL", "Designer", "Remote", "https://jobs/1", "2026-08-01T00:00:00Z", "https://api/1"),
            module.JobSignal("lever", "Example", "https://example.com", "NL", "Developer", "Amsterdam", "https://jobs/2", "2026-09-01T00:00:00Z", "https://api/1"),
        ]
        result = module.aggregate(signals, 100)
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["job_title"], "Developer")
        self.assertIn("2 openbare vacatures", result[0]["trigger_evidence"])
        self.assertTrue(result[0]["requires_compliance_review"])

    def test_recruitee_subdomain_validation(self):
        source = module.SourceSpec("recruitee", "bad/account", "Example", "https://example.com")
        with self.assertRaises(ValueError):
            module.fetch_recruitee(source, 10)


if __name__ == "__main__":
    unittest.main()
