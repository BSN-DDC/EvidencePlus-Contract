# 电子存证合约
[![Smart Contract](https://badgen.net/badge/smart-contract/Solidity/orange)](https://soliditylang.org/) 

电子存证是一种用于保存证据的手段，应用场景很多，例如在版权领域，作者可以将作品指纹保存到电子存证机构，当出现版权纠纷时，可通过取证解决纠纷。存证、取证的关键环节是电子存证服务机构，如何保证它的可信性，即存证机构本身不会对存证数据进行破坏？传统的中心化存证机构很难解决这个问题，需要由区块链技术来解决。在区块链技术中，电子账本由各个节点共同维护，其内容由共识算法决定，单一节点无法篡改已达成共识的账本数据。这一不可篡改的特性是去中心化电子存证方案的核心。该方案中，存证数据不再存储于单一机构，而是分布式地存储在所有区块链节点上。

## 前提条件

在使用智能合约之前，必须对以太坊和Solidity有基本的了解。
有关智能合约入门的全面指南，请参阅我们的[初学者指南](https://github.com/BSN-DDC/docs/blob/main/BSN-DDC%E7%BD%91%E7%BB%9C%E9%83%A8%E7%BD%B2Solidity%E5%90%88%E7%BA%A6%E5%BF%AB%E9%80%9F%E4%B8%8A%E6%89%8B%E6%8C%87%E5%8D%97.pdf)。

## 合约概述

电子数据存证是记录“用户身份验证-数据创建-存储-传输”全过程的方式，应用一系列安全技术全方位确保电子数据的真实性、完整性、安全性，在司法上具备完整的法律效力。

使用区块链+智能合约进行数据存证，具有以下优势：

防篡改机制：使用区块链技术保全证据，进一步加强了证据不可篡改性。

证据效力得到机构认可：司法机构作为链上节点，对链数据参与认可和签名，事后可从链上确认数据的真实有效性。

服务持续有效：数据被多方共识上链后，即使有部分共识方退出也不会造成数据的丢失或失效。



## 合约更新升级设计说明

合约结构通过ERC1967和UUPS（EIP-1822: Universal Upgradeable Proxy Standard）模式实现其业务合约的可升级。每一个业务合约绑定一个代理合约。

业务合约：

  -继承UUPSUpgradeable。该类库实现了UUPS代理设计的可升级机制。

  -添加初始化方法initialize()。用于代理合约部署时调用以进行合约的初始化操作。
	
业务合约的部署过程如下：

  -部署业务合约。 

  -部署代理合约ERC1967Proxy。部署时构造传参写入业务合约地址、initialize的方法签名，实现其与业务合约的映射以及初始化操作。
	
业务合约的升级过程如下：

  -部署新版本的业务合约。

  -调用当前代理合约中的upgradeTo方法。执行时传入新的业务合约地址，实现其与新版本业务合约的映射，达到升级的目的。	



## 部署说明

通过 [GitHub](https://github.com/BSN-DDC/EvidencePlus-Contract.git) 进行下载,或者通过以下命令进行拉取：

```
$ git clone git@github.com:BSN-DDC/EvidencePlus-Contract.git

```


存在合约的部署过程，请按以下步骤操作：

1. 部署evidence合约。
2. 部署代理合约ERC1967Proxy：参数：_logic填入第一步业务合约的合约地址、_data填入initialize的方法签名“0x8129fc1c”并部署。


## 主要功能

### 设置投票阈值
setThreshold(uint8 number): 设置投票阈值。

合约owner调用setThreshold设置投票阈值。

### 添加审核方
configureAuditor(address auditor, bool approval, bytes32 did): 添加审核方：auditor审核方账户、approval授权标识。

合约owner调用 configureAuditor添加审核方账户，成为审核方后可以对发起的存证请求数据进行审核以及投票操作。

### 存证方提交存证请求
createSaveRequest(bytes32 hash, address owner, bytes memory remaks): 存证方提交存证请求。hash是存证数据摘要，owner归属方， remaks说明信息。

存证方调用createSaveRequest将存证信息进行上链请求操作。

### 删除存证请求
deleteSaveRequest(bytes32 hash)：删除存证请求。存证方通过调用此接口将投票未通过的存证请求数据进行删除。

存证方调用deleteSaveRequest将投票未通过的存证请求数据进行删除。

### 查看存证请求
getRequestData(bytes32 hash): 查看存证请求，以便审核。包括creator发起方、remaks说明等信息。

调用getRequestData获取存证请求的上链数据信息。

### 审批存证请求
voteSaveRequest(bytes32 hash, bool status)：审核方审批存证请求。status：true审核通过。

审核方调用voteSaveRequest可以对未通过投票的存证请求数据进行投票,投票通过数大于等于投票阈值即审核通过。

### 查看存证数据
getEvidence(bytes32 hash): 取证方查看存证数据，包括时间戳、发起方、说明等信息。

取证方调用getEvidence获取存证的上链数据信息。

### 对存证数据启用或禁用
setStatus(bytes32 hash, bool status): 启用、禁用，对存证数据启用或禁用。

合约owner调用setStatus设置存证的上链数据启用或禁用。



