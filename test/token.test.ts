import { expect } from 'chai'
import { ethers } from 'hardhat'
import { Signer, ZeroAddress, encodeBytes32String, parseEther } from 'ethers'
import {
  Token,
  Token__factory,
  TokenImplementation,
  TokenImplementation__factory,
  ERC6551Registry,
  ERC6551Registry__factory
} from '../typechain-types'

import { ERC721Mock } from '../typechain-types/contracts/mock'
import { ERC721Mock__factory } from '../typechain-types/factories/contracts/mock'

describe('Token', function () {
  let token: Token
  let tokenImplementation: TokenImplementation
  let registry: ERC6551Registry
  let tokenMock: ERC721Mock

  let TokenFactory: Token__factory
  let RegistryFactory: ERC6551Registry__factory
  let TokenImplementationFactory: TokenImplementation__factory
  let TokenMockFactory: ERC721Mock__factory

  let owner: Signer
  let user: Signer

  let uri: string

  beforeEach(async function () {
    // Deploy ERC6551 Registry
    RegistryFactory = (await ethers.getContractFactory(
      'ERC6551Registry'
    )) as ERC6551Registry__factory
    registry = await RegistryFactory.deploy()
    await registry.waitForDeployment()

    // Deploy Token Implementation
    TokenImplementationFactory = (await ethers.getContractFactory(
      'TokenImplementation'
    )) as TokenImplementation__factory
    tokenImplementation = await TokenImplementationFactory.deploy()
    await tokenImplementation.waitForDeployment()

    // Deploy Token
    TokenFactory = (await ethers.getContractFactory('Token')) as Token__factory
    token = await TokenFactory.deploy(
      await tokenImplementation.getAddress(),
      await registry.getAddress()
    )
    await token.waitForDeployment()

    // Deploy Mock Token
    TokenMockFactory = (await ethers.getContractFactory('ERC721Mock')) as ERC721Mock__factory
    tokenMock = await TokenMockFactory.deploy()
    await tokenMock.waitForDeployment()

    // Initialise Actors
    ;[owner, user] = await ethers.getSigners()
  })

  describe('Mint', function () {
    it('Should be mintable', async function () {
      await token.connect(user).mint()
      expect(await token.ownerOf(0)).to.equal(await user.getAddress())
    })
  })

  describe('Token Bound Address', function () {
    it('Should have a token bound address', async function () {
      const tokenId = 0
      await token.connect(user).mint()

      const TBA = await token.connect(user).getAccount(tokenId)

      // Check TBA exists
      expect(TBA).to.not.equal(ZeroAddress)

      // Check predicted TBA matches registry
      expect(TBA).to.equal(
        await registry.account(
          await tokenImplementation.getAddress(),
          encodeBytes32String(''), // 0
          31337,
          await token.getAddress(),
          tokenId
        )
      )
    })
    it('Should call on behalf of TBA', async function () {
      const mintValue = parseEther('0')
      const tokenId = 0

      console.log(await token.getAddress())

      await token.connect(user).mint()

      // await token.connect(user).createAccount(tokenId)

      await token.connect(user).call(tokenId, await tokenMock.getAddress())
    })
  })
})
