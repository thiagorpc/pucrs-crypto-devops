// crypto-api/src/health/health.service.ts
import { Injectable } from '@nestjs/common';

@Injectable()
export class HealthService {
  /**
   * Retorna o status de saude do serviço (BackEnd).
   * Em projetos reais, ele também verificaria a conexão com o banco de dados.
   */
  checkStatus(): { status: string; timestamp: string } {
    return {
      status: 'OK',
      timestamp: new Date().toISOString(),
    };
  }
}
