from bitcoinaddress import Wallet
import ecdsa
import hashlib
import binascii
import base58
from requests import api
from fernet import Fernet
import base64


def create_btc_address():
    ecdsaPrivateKey = ecdsa.SigningKey.generate(curve=ecdsa.SECP256k1)
    print("ECDSA Private Key: ", ecdsaPrivateKey.to_string().hex())

    ecdsaPublicKey = '04' + ecdsaPrivateKey.get_verifying_key().to_string().hex()
    print("ECDSA Public Key: ", ecdsaPublicKey)

    hash256FromECDSAPublicKey = hashlib.sha256(
        binascii.unhexlify(ecdsaPublicKey)).hexdigest()
    ridemp160FromHash256 = hashlib.new(
        'ripemd160', binascii.unhexlify(hash256FromECDSAPublicKey))

    print("RIDEMP160(SHA256(ECDSA Public Key)): ",
          ridemp160FromHash256.hexdigest())

    prependNetworkByte = '00' + ridemp160FromHash256.hexdigest()
    print("Prepend Network Byte to RIDEMP160(SHA256(ECDSA Public Key)): ",
          prependNetworkByte)

    hash = prependNetworkByte
    for x in range(1, 3):
        hash = hashlib.sha256(binascii.unhexlify(hash)).hexdigest()
        print("\t|___>SHA256 #", x, " : ", hash)

    cheksum = hash[:8]
    print("Checksum(first 4 bytes): ", cheksum)

    appendChecksum = prependNetworkByte + cheksum
    print("Append Checksum to RIDEMP160(SHA256(ECDSA Public Key)): ", appendChecksum)

    bitcoinAddress = base58.b58encode(
        binascii.unhexlify(appendChecksum)).decode('utf8')
    print(f"Bitcoin Address: {bitcoinAddress}")
    return {'public_key': ecdsaPublicKey, 'private_key': ecdsaPrivateKey.to_string().hex(), 'address': bitcoinAddress}


def get_address_data(address):
    url = f'https://mempool.space/api/address/{address}'
    x = api.get(url)
    return x.json()


encoding = 'ascii'
key = 'QFShH23u7s_93dZlVkvN2o6xWL2wlkDccnUQq1Vtv2A='.encode()
fernet = Fernet(key)

def encrypt(data):
    return fernet.encrypt(data.encode(encoding)).decode(encoding)


def decrypt(data):
    return fernet.decrypt(data.encode(encoding)).decode(encoding)
