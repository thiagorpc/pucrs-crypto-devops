// security.service.spec.ts
import { ConfigService } from '@nestjs/config';
import { Test, TestingModule } from '@nestjs/testing';
import { randomBytes } from 'crypto';
import { SecurityService } from './security.service';

describe('SecurityService', () => {
  let service: SecurityService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SecurityService,
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn().mockImplementation((key: string) => {
              if (key === 'ENCRYPTION_KEY')
                return '12345678901234567890123456789012';
              return null;
            }),
          },
        },
      ],
    }).compile();

    service = module.get<SecurityService>(SecurityService);

    // Mock do logger para não poluir testes
    service['logger'] = {
      error: jest.fn(),
      warn: jest.fn(),
      log: jest.fn(),
    } as any;
  });

  it('deve estar definido', () => {
    expect(service).toBeDefined();
  });

  it('deve gerar a mesma chave a partir do mesmo salt', async () => {
    const salt = randomBytes(16).toString('hex');
    const key1 = await service.generateKey(salt);
    const key2 = await service.generateKey(salt);
    expect(key1).toEqual(key2);
  });

  it('deve criptografar e descriptografar uma string corretamente', async () => {
    const text = 'Mensagem secreta!';
    const encrypted = await service.encryptAES_256_GCM(text);
    const decrypted = await service.decryptAES_256_GCM(encrypted);
    expect(decrypted).toBe(text);
  });

  it('deve criptografar e descriptografar um objeto JSON corretamente', async () => {
    const obj = { user: 'john', roles: ['admin', 'user'] };
    const encrypted = await service.encryptObject(obj);
    const decryptedObj = await service.decryptToObject<typeof obj>(encrypted);
    expect(decryptedObj).toEqual(obj);
  });

  it('deve lançar erro ao tentar descriptografar string inválida', async () => {
    await expect(service.decryptAES_256_GCM('string_invalida')).rejects.toThrow(
      'Falha na decriptografia. Dados corrompidos ou chave incorreta.',
    );
  });

  it('deve assinar e verificar dados corretamente', () => {
    const data = 'dados para assinar';
    // Para testes, criamos um par de chaves RSA gerado aleatoriamente
    const { generateKeyPairSync } = require('crypto');
    const { privateKey, publicKey } = generateKeyPairSync('rsa', {
      modulusLength: 2048,
    });

    const signature = service.signData(data, privateKey);
    const isValid = service.verifySignature(data, publicKey, signature);
    expect(isValid).toBe(true);
  });

  it('deve retornar falso se a assinatura não bater', () => {
    const data = 'dados para assinar';
    const { generateKeyPairSync } = require('crypto');
    const { privateKey, publicKey } = generateKeyPairSync('rsa', {
      modulusLength: 2048,
    });

    const signature = service.signData(data, privateKey);
    const isValid = service.verifySignature(
      'dados_errados',
      publicKey,
      signature,
    );
    expect(isValid).toBe(false);
  });
});
