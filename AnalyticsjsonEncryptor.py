from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import padding
import json
import base64
import binascii

# AES key used for encryption and decrypion for analytic JSON file (in hex format)
aes_key_hex = "[you key goes here]"
aes_key_bytes = bytes.fromhex(aes_key_hex) # Convert hex key to bytes
iv = b'\x00' * 16  # IV used in C# encryption
cipher = Cipher(algorithms.AES(aes_key_bytes), modes.CBC(iv), backend=default_backend()) # Create AES cipher with CBC mode

# Create a Encrypter and decryptor objects
decryptor = cipher.decryptor()
encryptor = cipher.encryptor()

def encryption(input_file, Output_Encrypted_file):
    with open(input_file, 'r') as file:
        json_data = json.load(file)
        json_string = json.dumps(json_data)
        json_encoded = json_string.encode('utf-8')
        # Pad the data to match the block size (AES block size is 128 bits)
        block_size = 128 // 8  # Block size in bytes (128 bits)
        remainder = len(json_encoded) % block_size
        if remainder != 0:
            # Calculate padding length needed
            padding_length = block_size - remainder
            # Apply PKCS7 padding manually
            json_encoded += bytes([padding_length]) * padding_length
        encrypted_data = encryptor.update(json_encoded) + encryptor.finalize()
        # Encode the encrypted data to Base64
        base64_encoded = base64.b64encode(encrypted_data).decode('utf-8')
        with open(Output_Encrypted_file, 'w') as encrypted_file_out:
            encrypted_file_out.write(base64_encoded)
            print("Encryption completed.")

# File Paths
input_file = 'C:\\Users\\hp\\Documents\\analytic_json\\motor_hi_weighatge_json.txt'
Output_Encrypted_file = 'C:\\Users\\hp\\Documents\\analytic_json\\Encrypted\\motor_hi_weighatge_json_Encrypted_Json.txt'
Output_Decrypted_file = 'C:\\Users\\hp\\Documents\\analytic_json\\Decrypted\\motor_hi_weighatge_json_Decrypted_Json.txt'

#Decryption
def decryption(input_file, Output_Decrypted_file):
    with open(input_file, 'rb') as file:
        encrypted_data = file.read()
        encrypted_bytes = base64.b64decode(encrypted_data)  # Decode Base64 encoded ciphertext
        decrypted_data = decryptor.update(encrypted_bytes) + decryptor.finalize()
        unpadder = padding.PKCS7(128).unpadder()  # Ensure proper padding and block size
        decrypted_data_unpadded = unpadder.update(decrypted_data) + unpadder.finalize()
        decrypted_json = decrypted_data_unpadded.decode('utf-8')  # Decode the decrypted data as UTF-8
        return decrypted_json
        with open(Output_Decrypted_file, 'w') as decrypted_file_out:
            decrypted_file_out.write(decrypted_json)
            print("Decryption completed.")

# File Paths
input_file = 'C:\\Users\\hp\\Documents\\analytic_json\\motor_hi_weighatge_json.txt'
# input_file = 'C:\\Users\\hp\\Documents\\analytic_json\\transformer_hi_weightage_Encrypted_Json.txt'
Encrypted_file = 'C:\\Users\\hp\\Documents\\analytic_json\\Encrypted\\transformer_hi_weightage_Encrypted_Json.txt'
Decrypted_file = 'C:\\Users\\hp\\Documents\\analytic_json\\Decrypted\\transformer_hi_weightage_Decrypted_Json.txt'

# Input from users
auth = str(input("Please enter your 'first' and 'last' letter of your full name (Eg: virat kohli = vi): \n "))
if auth in ['ar', 'si', 'pr', 've', 'sr', 'sm', 'sa']:
    print("Authentication is successful")
    choice = int(input("Please select one: Enter 1 for encryption / 2 for decryption: "))
    if choice == 1:
        encryption(input_file, Encrypted_file)
        print("Encrypted data has saved to path:", Encrypted_file)
        # print("Encryption is disabled")
    elif choice == 2:
        decryption(input_file, Decrypted_file)
        print("Decrypted data has saved to path:", Decrypted_file)
    else:
        print("Invalid choice.")
else:
    print("Authentication Failed")
