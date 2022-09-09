Running QuartiCal on EC2
########################

QuartiCal is a Python package implementing calibration routines for radio interferometer data.
Its documentation is available on `readthedocs <https://quartical.readthedocs.io/en/latest/>`_.

Starting the EC2 instance
*************************

This tutorial is packaged with a script for bringing up the networking interface
for an EC2 instance. The following will create a ``quartical-test`` Virtual Private Cloud
along with other networking components and assign their ID's to environment variables
and then start an EC2 instance.

.. code-block:: bash

    $ source ./ec2-setup.sh
    $ export INSTANCE_ID=$(aws ec2 run-instances \
        --image-id $AMI \
        --region $REGION \
        --key-name $KEY_NAME \
        --subnet-id $SUBNET \
        --security-group-id $SECGRP \
        --instance-type $INSTANCE_TYPE \
        --block-device-mapping file://mapping.json \
        --associate-public-ip-address \
        --query "Instances[*].InstanceId" \
        --output text)

Give the instance some time to spin up before obtaining it's public IP address
andd SSH'ing into the box

.. code-block:: bash

    $ export IP=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --query "Reservations[*].Instances[*].PublicIpAddress" \
        --output text)
    $ ssh -i quartical.pem ubuntu@$IP

Install Quartical
*****************

Run the following

.. code-block:: bash

    $ sudo apt update -y
    $ sudo apt install -y python3 python3-pip python-is-python3 awscli
    $ sudo pip install quartical


Running Quartical
*****************

For the sake of simplicity, create a working directory and download
the reduction data into it:

.. code-block:: bash

    $ mkdir data
    $ cd data
    $ curl https://ratt-public-data.s3.af-south-1.amazonaws.com/eso.ms.tar.gz | tar xzvf -

The default arguments will solve for a high time and frequency resolution gain term and
output the results to ``gains.qc``:

.. code-block:: bash

    $ goquartical \
        input_ms.path=~/data/ms1_primary_subset.ms \
        input_model.recipe=MODEL_DATA

This is the simplest use of QuartiCal. A more realistic command, performing typical gain,
delay and bandpass calibration, would be:

.. code-block:: bash

    $ goquartical \
        input_ms.path=~/data/ms1_primary_subset.ms \
         input_model.recipe=MODEL_DATA \
         solver.terms="[G,K,B]" \
         solver.iter_recipe="[100,100,100]" \
         G.type=diag_complex \
         G.time_interval=0 \
         G.freq_interval=0 \
         K.type=delay \
         K.time_interval=0 \
         K.freq_interval=0 \
         B.type=complex \
         B.time_interval=0 \
         G.freq_interval=1 \
         output.overwrite=1

These options, which can become quite lengthy, can instead be specified via a .yaml file.
To create a .yaml file with a name of your choice, run:

.. code-block:: bash

    $ goquartical-config config.yaml

The contents of ``config.yaml`` can be edited to contain all the arguments listed above.
Invoking QuartiCal then becomes as simple as running:

.. code-block:: bash

    $ goquartical config.yaml

For assistance with any argument, running ``goquartical``
without arguments will print detailed help.

The above commands will write their gain outputs to `gains.qc` as zarr arrays.
These have a directory structure that will look like this:

::

    gains.qc
    ├── B
    ├── G
    └── K

Stopping the EC2 instance
*************************

Terminate the EC2 instance

.. code-block::

    $ aws ec2 terminate-instances --instance-ids $INSTANCE_ID

Repeat the above until it's current state is terminated before running:

.. code-block::

    source ./ec2-cleanup.sh
