# Crea una VPC
AWS_ID_VPC=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --output text --query 'Vpc.VpcId')

# Crea subredes pública y privada
AWS_ID_Subnet_Publica=$(aws ec2 create-subnet --vpc-id $AWS_ID_VPC --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --output text --query 'Subnet.SubnetId')

AWS_ID_Subnet_Privada=$(aws ec2 create-subnet --vpc-id $AWS_ID_VPC --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --output text --query 'Subnet.SubnetId')

# Crea una tabla de enrutamiento
AWS_ID_Tabla_Enrutamiento=$(aws ec2 create-route-table --vpc-id $AWS_ID_VPC --output text --query 'RouteTable.RouteTableId')

# Asocia la tabla de enrutamiento con la subred privada
aws ec2 associate-route-table --subnet-id $AWS_ID_Subnet_Privada --route-table-id $AWS_ID_Tabla_Enrutamiento

# Crea un NAT Gateway en la subred pública
AWS_ID_NAT_Gateway=$(aws ec2 create-nat-gateway --subnet-id $AWS_ID_Subnet_Publica --allocation-id <Allocation_ID_de_tu_IP_Elastica> --output text --query 'NatGateway.NatGatewayId')

# Agrega una ruta en la tabla de enrutamiento para redirigir el tráfico de la subred privada a través del NAT Gateway
aws ec2 create-route --route-table-id $AWS_ID_Tabla_Enrutamiento --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $AWS_ID_NAT_Gateway

# Crea un grupo de seguridad para la instancia EC2 en la subred privada
AWS_ID_GrupoSeguridad_EC2MOTI=$(aws ec2 create-security-group --group-name 'SecGroupMOTI' --description 'Permitir conexiones SSH' --vpc-id $AWS_ID_VPC --output text --query 'GroupId')

aws ec2 authorize-security-group-ingress --group-id $AWS_ID_GrupoSeguridad_EC2MOTI --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]'

# Crea la instancia EC2 en la subred privada
aws ec2 run-instances \
   --image-id ami-050406429a71aaa64 \
   --count 1 \
   --instance-type m1.small \
   --key-name vockey \
   --region us-east-1 \
   --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=EC2MOTI}]' \
   --security-group-ids $AWS_ID_GrupoSeguridad_EC2MOTI \
   --subnet-id $AWS_ID_Subnet_Privada
