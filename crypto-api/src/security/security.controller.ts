import {
  BadRequestException,
  Body,
  Controller,
  Get,
  Post,
  Query,
} from '@nestjs/common';
import { SecurityService } from './security.service';

@Controller('security')
export class SecurityController {
  constructor(private readonly securityService: SecurityService) {}

  /**
   * POST /security/encrypt
   * Criptografa um texto simples (ou JSON) usando AES-256-GCM.
   */
  @Post('encrypt')
  async encrypt(@Body('payload') payload: any) {
    if (!payload) {
      throw new BadRequestException('Campo "data" é obrigatório.');
    }

    const encrypted = await this.securityService.encryptAES_256_GCM(payload);
    return { encrypted };
  }

  /**
   * POST /security/decrypt
   * Descriptografa um texto criptografado.
   */
  @Post('decrypt')
  async decrypt(@Body('encrypted') encrypted: string) {
    if (!encrypted) {
      throw new BadRequestException('Campo "encrypted" é obrigatório.');
    }

    const decrypted = await this.securityService.decryptAES_256_GCM(encrypted);
    return { decrypted };
  }

  /**
   * GET /security/test
   * Endpoint de teste rápido (criptografa e decriptografa automaticamente)
   */
  @Get('test')
  async test(@Query('text') text: string) {
    if (!text) {
      throw new BadRequestException(
        'Informe um texto via query param: ?text=algo',
      );
    }

    const encrypted = await this.securityService.encryptAES_256_GCM(text);
    const decrypted = await this.securityService.decryptAES_256_GCM(encrypted);

    return {
      original: text,
      encrypted,
      decrypted,
    };
  }
}
