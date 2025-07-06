#!/bin/bash

# دایرکتوری برای فایل‌های workload
mkdir -p workload

# تولید فایل callback.js
cat << EOF > workload/callback.js
'use strict';

const { WorkloadModuleBase } = require('@hyperledger/caliper-core');

class MyWorkload extends WorkloadModuleBase {
    constructor() {
        super();
        this.chaincodeID = '';
        this.channel = '';
        this.contractFunction = '';
        this.contractArguments = [];
    }

    async initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext) {
        await super.initializeWorkloadModule(workerIndex, totalWorkers, roundIndex, roundArguments, sutAdapter, sutContext);
        this.chaincodeID = this.roundArguments.chaincodeID;
        this.channel = this.roundArguments.channel;
        this.contractFunction = this.roundArguments.contractFunction;
        this.contractArguments = this.roundArguments.contractArguments;
    }

    async submitTransaction() {
        const request = {
            contractId: this.chaincodeID,
            contractFunction: this.contractFunction,
            contractArguments: this.contractArguments,
            channel: this.channel,
            readOnly: this.contractFunction === 'QueryResource'
        };
        return this.sutAdapter.invokeSmartContract(this.sutContext, request.contractId, undefined, request);
    }

    async cleanupWorkloadModule() {
        // No cleanup required
    }
}

async function createWorkloadModule() {
    return new MyWorkload();
}

module.exports.createWorkloadModule = createWorkloadModule;
EOF

echo "Generated workload/callback.js for Caliper tests"
