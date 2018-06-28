{
    "terraform": {
        "backend": {
            "s3": {
                "bucket": "tfstate-vaultlab-dev", 
                "key": "tfStateFile-vaultlab-dev", 
                "region": "us-east-2"
            }
        }
    }
}