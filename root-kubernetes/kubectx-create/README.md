# Kubernetes Group, Role, Account

## Creating a user in `admin` group

```bash
COMPANY={COMPANY} PROJECT={PROJECT} USERID={VALUE} ./create-admin.sh

# for example,
# COMPANY=YO PROJECT=MYPRJ USERID={1ambda} ./create-admin.sh
```

## Register kubectl context from the created csr files

Unzip the generated `.zip` file and execute `*_register.sh`. You should has `.csr`, `.crt` and `.pem` file in the same directory.

```bash
# for example

./yo_myprj_1ambda_register.sh
```