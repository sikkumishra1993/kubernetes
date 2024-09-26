# Create ACR
az acr create --resource-group myResourceGroup --name myRegistry --sku Basic --admin-enabled true

# Log in to ACR
az acr login --name myRegistry

# Tag the image
docker tag my-node-app myRegistry.azurecr.io/my-node-app:v1

# Push the image
docker push myRegistry.azurecr.io/my-node-app:v1

# Verify the image
az acr repository list --name myRegistry --output table

az login

az acr login --name myRegistry --

ACR_USERNAME=$(az acr credential show --name myRegistry --query "username" --output tsv)
ACR_PASSWORD=$(az acr credential show --name myRegistry --query "passwords[0].value" --output tsv)

kubectl create secret docker-registry acr-secret \
  --docker-server=myRegistry.azurecr.io \
  --docker-username=$ACR_USERNAME \
  --docker-password=$ACR_PASSWORD \
  --docker-email=myemail@example.com

apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: my-app
        image: myRegistry.azurecr.io/smitest:v1
        ports:
        - containerPort: 80
      imagePullSecrets:
      - name: acr-secret
