# This is an old version. A new version that only requires a single BaSH script is available here:
https://github.com/Zerto-TA-Public/Zerto-MongoDB-Checkpoints-Linux
# MongoDB-Journal-Checkpoints
These scripts are used to add a Quiesced User Checkpoint to the Zerto Journal of a MongoDB server. The result is that MongoDB will flush all pending writes to disk, and pause new writes long enough for Zerto to insert a checkpoint into the journal which has all database records.

## Getting Started

There are several pieces to this project. Some of which are placed on your Linux based MongoDB server, and another that gets placed on a Windows based machine. 

At a high level the process for a MongoDB Journal Checkpoint looks like this:
1. Windows Scheduled Task (or other scheduling engine) calls the MongoDB-Journal-Checkpoint.ps1 script
2. The Powershell script connects to the MongoDB Linux Server
3. The MongoDB server executes mongo_freeze.sh script, which freezes MongoDB
4. The Powershell script verifies that the DB is locked (if not it tries two more times).
5. The PowerShell script calls ZVM and inserts a User Checkpoint for the specified VPG
6. The PowerShell script executes mongo_unfreeze.sh script, which unfreezes MongoDB (it will continue to retry until the DB is unlocked).
7. The PowerShell script disconnects the SSH session

## Prerequisites

* Zerto PowerShell Module must be installed on the Windows Machine
* PoSH-SSH PowerShell Module must be installed on the Windows Machine
* You must create an RSA keypair for passwordless authentication to your MongoDB Linux Server (and copy the private key to the Windows Machine)
* PowerShell "Set-ExecutionPolicy Unrestricted" on Windows Machine
```
Set-ExecutionPolicy Unrestricted
```

## Installing

Download or clone the git repository to your Linux MongoDB server, then make the two bash scripts (mongo_freeze.sh and mongo_unfreeze.sh) executable. After that copy them to /usr/local/bin or another directory in your user accounts PATH.

```
git clone https://www.github.com/zerto-ta-public/MongoDB-Journal-Checkpoint/
chmod +x mongo_*
sudo cp mongo_* /usr/local/bin/
```

Next, to enable password-less authenication, create an RSA keypair on the MongoDB server and add the public key to the authorized_keys file.

When asked the questions by ssh-keygen, just hit enter on all questions.

```
ssh-keygen rsa
cat ~/.ssh/id_rsa >> ~/.ssh/authorized_keys
```

Next move both the private key from your .ssh/ folder as well as the Zerto-Mongo-Checkpoint.ps1 script to your Windows host using WinSCP or something similar. 

## Usage

For a full walkthrough of this project please see https://www.jpaul.me/?p=12645

## Versioning

This script is considered the initial release and version 1.0.0 

## Authors

* **Justin Paul** - *Initial work* - [recklessop](https://github.com/recklessop) - [Blog](https://jpaul.me)

## Contributors
* **Shannon Snowden** - *Script Review* - [shannonsnowden](https://github.com/shannonsnowden) - [Blog](http://virtualizationinformation.com/)

## License

This project is licensed under the GNU GPLv3 License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Google
* Zerto Documentation
* etc
