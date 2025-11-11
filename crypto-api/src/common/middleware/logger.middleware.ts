import { Injectable, Logger, NestMiddleware } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';

@Injectable()
export class LoggerMiddleware implements NestMiddleware {
  private logger = new Logger('HTTP');

  use(req: Request, res: Response, next: NextFunction) {
    const { method, originalUrl } = req;
    const startTime = Date.now();

    // Tenta obter o IP de origem real, verificando o cabeçalho X-Forwarded-For (comum em Load Balancers/API Gateways)
    const ip = req.headers['x-forwarded-for'] || req.ip;

    // Log inicial da requisição
    const logMessage = `${method} ${originalUrl} | IP: ${ip}`;
    this.logger.log(logMessage);

    // Registra o evento de conclusão da resposta
    res.on('finish', () => {
      const { statusCode } = res;
      const duration = Date.now() - startTime;
      const contentLength = res.get('content-length');

      // Log de resposta final com status e IP
      this.logger.log(
        `${method} ${originalUrl} ${statusCode} ${contentLength} - ${duration}ms | IP: ${ip}`,
        'HTTP Response',
      );
    });

    next();
  }
}
