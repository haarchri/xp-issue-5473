
# 1.13.2-up.3
```bash
helm repo update
UPTEST_CLOUD_CREDENTIALS=$(cat ~/.aws/uptest) ./setup.sh 1.13.2-up.3
```

-> no issue

# 1.14.6-up.1 and 1.15.0-up.1
```bash
helm repo update
UPTEST_CLOUD_CREDENTIALS=$(cat ~/.aws/uptest) ./setup.sh 1.14.6-up.1
```

```bash
helm repo update
UPTEST_CLOUD_CREDENTIALS=$(cat ~/.aws/uptest) ./setup.sh 1.15.0-up.1
```

-> issue

```bash
  Warning  ComposeResources         20s (x7 over 78s)    defined/compositeresourcedefinition.apiextensions.crossplane.io  cannot compose resources: cannot parse base template of composed resource "iam": cannot change the kind or group of a composed resource from iam.aws.crossplane.io/v1beta1, Kind=Role to iam.aws.upbound.io/v1beta1, Kind=Role (possible composed resource template mismatch)
```
