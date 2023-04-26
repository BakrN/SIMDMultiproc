from utils import verify
import sys

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 verifier.py <file1> <file2>")
        sys.exit(1)
    print(f"Total descrepencies: {verify(sys.argv[1], sys.argv[2]) } ") 



