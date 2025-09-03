import unittest
from unittest.mock import Mock, patch

from fastapi.testclient import TestClient
from main import app


class TestFastAPI(unittest.TestCase):

    def setUp(self):
        self.client = TestClient(app)

    def test_health(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {
            "Status": "Success"
        })

    def test_ping_service_a(self):
        mock_response = Mock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"message": "Greetings from Service A!"}

        with patch('httpx.Client') as mock_client_class:
            mock_client = Mock()
            mock_client.get.return_value = mock_response
            mock_client_class.return_value.__enter__.return_value = mock_client
            mock_client_class.return_value.__exit__.return_value = None # it's used to clean up the context manager of the `with` block

            response = self.client.get("/ping_service_a")

            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.json(), {
                "message": "Greetings from Service A! (via Service B)"
            })

