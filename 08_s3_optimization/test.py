import boto3

s3 = boto3.client("s3")

buckets = s3.list_buckets()

for bucket in buckets["Buckets"]:
    print(bucket)
#    last_modified = bucket["LastModified"]
#    if last_modified < datetime.datetime.now() - datetime.timedelta(days=60):
#        print(bucket["Name"])

