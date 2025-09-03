import unittest
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

    def test_ping(self):
        response = self.client.get(f"/ping")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {
            "message": "Greetings from Service A!"
        })
