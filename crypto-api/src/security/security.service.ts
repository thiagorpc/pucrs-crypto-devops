//import * as argon2 from 'argon2';

import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  createCipheriv,
  createDecipheriv,
  createSign,
  createVerify,
  randomBytes,
  scrypt,
} from 'crypto';

import { promisify } from 'util';

/**
 * Define os algoritmos suportados para criptografia e decriptografia.
 */
export enum CryptoAlgorithm {
  AES_256_GCM = 'aes-256-gcm',
}

@Injectable()
export class SecurityService {
  private readonly logger = new Logger(SecurityService.name, {
    timestamp: true,
  });
  private readonly secretKey: string;

  // Novo padrão de configuração para ao Argon2.
  //public readonly _argon2Options: Options & { type: number } = {
  //  // Argon2id é a variante mais segura e recomendada
  //  type: argon2.argon2id,
  //
  //  // 64MB de memória (custo de memória)
  //  memoryCost: 65536,
  //
  //  // Numero de iterações (custo de tempo)
  //  timeCost: 3,
  //
  //  // Threads de CPU (custo de paralelismo)
  //  parallelism: 4,
  //};

  // public readonly _argon2Options = {
  //   type: argon2.argon2id,
  //   memoryCost: 65536,
  //   timeCost: 3,
  //   parallelism: 4,
  // } as const;

  constructor(private readonly configService: ConfigService) {
    this.secretKey =
      this.configService.get<string>('ENCRYPTION_KEY') ?? 'ENCRYPTION_KEY';

    if (!this.secretKey) {
      throw new Error(
        'A variável de ambiente ENCRYPTION_KEY não está definida.',
      );
    }

    if (this.secretKey.length < 32) {
      throw new Error('A ENCRYPTION_KEY deve ter pelo menos 32 caracteres.');
    }
  }

  //argon2Options() {
  //  return this._argon2Options;
  //}

  async generateKey(salt: string | Buffer): Promise<Buffer> {
    let saltBuffer: Buffer;

    // Converte a string (hex) para Buffer. Isso garante consistência.
    if (typeof salt === 'string') {
      saltBuffer = Buffer.from(salt, 'hex');
    } else {
      saltBuffer = salt;
    }

    // A chave é derivada a partir da Secret Key, do Salt (como Buffer) e do tamanho (32 bytes)
    const key = (await promisify(scrypt)(
      this.secretKey,
      saltBuffer,
      32,
    )) as Buffer;
    return key;
  }

  public async encryptAES_256_GCM(payload: unknown): Promise<string> {
    //
    let textToEncrypt: string;

    // 1. GARANTIR QUE O DADO É UMA STRING (Lógica de Serialização)
    if (typeof payload === 'string') {
      textToEncrypt = payload;
    } else {
      // Se for um objeto JSON (ou qualquer outra coisa), serializa para string.
      try {
        textToEncrypt = JSON.stringify(payload);
      } catch (e) {
        const errorMessage = String(e instanceof Error ? e.message : e);

        this.logger.warn(
          `Falha ao serializar dado para criptografia: ${errorMessage}`,
        );
        throw new Error('O dado fornecido não pode ser serializado para JSON.');
      }
    }

    try {
      // 1. Gere IV (12 bytes é o recomendado para GCM)
      const iv = randomBytes(12);
      const ivHex = iv.toString('hex'); // Converte para HEX

      // 2. Gere um Salt randômico (32 bytes = 64 caracteres HEX)
      const salt = randomBytes(32).toString('hex');

      // 3. Gera a Chave de Criptografia usando o Salt (Key Derivation)
      const key = await this.generateKey(salt);

      // 4. Cria e executa o Cipher
      //    Nota: Assumindo que key é um Buffer ou já foi convertida em generateKey.
      const cipher = createCipheriv(
        CryptoAlgorithm.AES_256_GCM,
        key, // Usando a chave derivada
        iv,
      );

      // Criptografa
      let encrypted = cipher.update(textToEncrypt, 'utf8', 'hex');
      encrypted += cipher.final('hex');

      // 5. Gera a Tag de Autenticação
      const tag = cipher.getAuthTag().toString('hex');

      // 6. Constrói e retorna a string final no formato: IV:CIPHERTEXT:TAG.SALT
      //    - Partes separadas por ':' para IV, Ciphertext, Tag
      //    - Separado por '.' para anexar o Salt no final.
      const resultString = `${ivHex}:${encrypted}:${tag}.${salt}`;

      return resultString;
    } catch (e) {
      const errorMessage = String(e instanceof Error ? e.message : e);

      this.logger.error(
        `❌ Erro crítico durante o processo de cifra AES-256-GCM: ${errorMessage}`,
      );
      throw new Error('Falha na operação de criptografia.');
    }
  }

  public async decryptAES_256_GCM(encryptedText: string): Promise<string> {
    try {
      // 1. SEPARAÇÃO PRINCIPAL: Divide a string pelo PONTO ('.') para isolar o Salt
      const [cipheredData, salt] = encryptedText.split('.');

      // VERIFICAÇÃO BÁSICA
      if (!cipheredData || !salt) {
        throw new Error('Formato da string criptografada inválido.');
      }

      // 2. SEPARAÇÃO SECUNDÁRIA: Divide o restante (cipheredData) pelo DOIS-PONTOS (':')
      const parts = cipheredData.split(':');

      // Verifica se temos as 3 partes esperadas
      if (parts.length !== 3) {
        throw new Error('Faltam componentes de IV, Ciphertext ou Tag.');
      }

      const iv = Buffer.from(parts[0], 'hex');
      const encrypted = parts[1];
      const tag = Buffer.from(parts[2], 'hex');

      // 3. DERIVAÇÃO DA CHAVE: Usa o Salt EXTRAÍDO para gerar a chave de descriptografia
      // Se a mudança no generateKey for feita, o 'salt' (string hex) será convertido lá.
      const key = await this.generateKey(salt);

      // 4. Cria Decipher
      const decipher = createDecipheriv(
        CryptoAlgorithm.AES_256_GCM,
        key, // Usamos 'key' (Buffer) diretamente
        iv,
      );

      // 5. Configura e Descriptografa
      decipher.setAuthTag(tag);

      let decrypted = decipher.update(encrypted, 'hex', 'utf8');
      decrypted += decipher.final('utf8');

      // 6. Desserializa o resultado JSON para o tipo 'any' esperado
      try {
        return decrypted;
      } catch (e) {
        const errorMessage = String(e instanceof Error ? e.message : e);

        this.logger.error(`❌ Erro durante a decriptografia: ${errorMessage}`);
        // Se falhar o parse, retorna a string pura (util para strings não-JSON)
        return decrypted;
      }
    } catch (e) {
      const errorMessage = String(e instanceof Error ? e.message : e);

      this.logger.error(`❌ Erro durante a decriptografia: ${errorMessage}`);
      // Lança uma exceção genérica para evitar vazar detalhes internos para o chamador

      throw new Error(
        'Falha na decriptografia. Dados corrompidos ou chave incorreta.',
      );
      //throw new Error( 'Falha na decriptografia. Dados corrompidos ou chave incorreta.' );
    }
  }

  // --- Métodos de Assinatura/Verificação (Conceitos RSA) ---

  /**
   * Demonstra o conceito de Assinatura Digital (Tipicamente RSA)
   * util para autenticar o emissor dos dados.
   * NOTA: Este é um exemplo conceitual, não um método de criptografia de dados.
   */
  public signData(data: string, privateKey: string): string {
    const signer = createSign('sha256');
    signer.update(data);
    return signer.sign(privateKey, 'hex');
  }

  /**
   * Demonstra o conceito de Verificação de Assinatura (Tipicamente RSA)
   */
  public verifySignature(
    data: string,
    publicKey: string,
    signature: string,
  ): boolean {
    const verifier = createVerify('sha256');
    verifier.update(data);
    return verifier.verify(publicKey, signature, 'hex');
  }

  /**
   * Facilita criptografar/decriptar payloads JSON inteiros.
   */
  public async encryptObject(obj: any): Promise<string> {
    return this.encryptAES_256_GCM(JSON.stringify(obj));
  }

  /**
   * Facilita criptografar/decriptar payloads JSON inteiros.
   */
  public async decryptToObject<T>(encrypted: string): Promise<T> {
    const decrypted = await this.decryptAES_256_GCM(encrypted);
    return JSON.parse(decrypted) as T;
  }
}
