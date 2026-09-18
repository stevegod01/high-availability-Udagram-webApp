import importlib.util
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("ec2_lab", Path(__file__).resolve().parents[1] / "labs/ec2-apache-ebs/lab.py")
lab = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lab)

STACK = {"Stacks": [{"StackStatus": "CREATE_COMPLETE", "Outputs": [
    {"OutputKey": "InstanceId", "OutputValue": "i-test"},
    {"OutputKey": "DataVolumeId", "OutputValue": "vol-test"}]}]}

class LabTests(unittest.TestCase):
    def args(self, *args):
        return lab.parse_args([*args, "--stack", "test-lab", "--region", "us-east-1"])

    def test_rejects_missing_or_invalid_cidr(self):
        for cidr in [None, "not-a-network", "203.0.113.10/24", "::/0"]:
            with self.subTest(cidr=cidr), self.assertRaises(SystemExit):
                self.args("deploy", *(["--http-cidr", cidr] if cidr else []))

    def test_cleanup_requires_exact_confirmation(self):
        with self.assertRaises(SystemExit):
            self.args("cleanup", "--confirm-stack", "different-stack")

    @patch.object(lab, "aws")
    def test_deployment_passes_explicit_parameters(self, aws):
        aws.side_effect = ["", json.dumps(STACK)]
        lab.run(self.args("deploy", "--http-cidr", "203.0.113.10/32"))
        command = aws.call_args_list[0].args
        self.assertIn("HttpCidr=203.0.113.10/32", command)
        self.assertIn("CAPABILITY_IAM", command)

    @patch.object(lab, "aws")
    def test_verify_refuses_wrong_attachment(self, aws):
        aws.side_effect = [json.dumps(STACK), "", json.dumps({"Volumes": [{"Attachments": [{"InstanceId": "i-other", "State": "attached"}]}]})]
        with self.assertRaises(RuntimeError):
            lab.run(self.args("verify"))

    @patch.object(lab, "aws")
    def test_verify_waits_and_checks_expected_attachment(self, aws):
        aws.side_effect = [json.dumps(STACK), "", json.dumps({"Volumes": [{"Attachments": [{"InstanceId": "i-test", "State": "attached"}]}]})]
        lab.run(self.args("verify"))
        self.assertEqual(aws.call_args_list[1].args[1:4], ("ec2", "wait", "instance-status-ok"))

    @patch.object(lab, "aws")
    def test_cleanup_waits_only_after_successful_delete(self, aws):
        lab.run(self.args("cleanup", "--confirm-stack", "test-lab"))
        self.assertEqual(aws.call_args_list[1].args[1:4], ("cloudformation", "wait", "stack-delete-complete"))
        aws.reset_mock()
        aws.side_effect = subprocess.CalledProcessError(1, "aws")
        with self.assertRaises(subprocess.CalledProcessError):
            lab.run(self.args("cleanup", "--confirm-stack", "test-lab"))
        self.assertEqual(aws.call_count, 1)

    @patch.object(lab.subprocess, "run")
    def test_process_uses_argument_list_and_propagates_failure(self, run):
        run.side_effect = subprocess.CalledProcessError(1, "aws")
        with self.assertRaises(subprocess.CalledProcessError):
            lab.aws(self.args("verify"), "ec2", "describe-instances")
        self.assertTrue(run.call_args.kwargs["check"])
        self.assertNotIn("shell", run.call_args.kwargs)

if __name__ == "__main__":
    unittest.main()
