import { Injectable, Logger, NestMiddleware } from '@nestjs/common';
import { NextFunction, Request, Response } from 'express';

@Injectable()
export class LoggerMiddleware implements NestMiddleware {
  // Use um nome de contexto para o logger
  private logger = new Logger('RequestLogger');

  use(req: Request, res: Response, next: NextFunction) {
    const { method, originalUrl, headers } = req;
    const startTime = Date.now();

    // Gera um ID de rastreamento para vincular requisição e resposta
    const requestId =
      headers['x-amzn-requestid'] || Math.random().toString(36).substring(2, 9);

    // Tenta obter o IP de origem real
    const ip = req.headers['x-forwarded-for'] || req.ip || '';

    // --- LOG DE INÍCIO DA REQUISIÇÃO (START) ---
    const requestLog = {
      timestamp: new Date().toISOString(),
      requestId: requestId,
      type: 'request_start',
      method: method,
      url: originalUrl,
      ip: ip,

      // O corpo da requisição é capturado aqui
      body: req.body || {},

      // Cabeçalhos (filtrados para evitar logs muito longos, ou use 'headers' completo se necessário)
      headers: {
        'user-agent': headers['user-agent'],
        'content-type': headers['content-type'],
        'x-forwarded-for': headers['x-forwarded-for'],
      },
    };

    // 🎯 Envia o objeto JSON para o console/CloudWatch
    // Usamos console.log() aqui para garantir que o output seja JSON puro sem a formatação extra do NestJS Logger
    console.log(JSON.stringify(requestLog));

    // --- LOG DE RESPOSTA FINAL (FINISH) ---
    res.on('finish', () => {
      const duration = Date.now() - startTime;
      const responseLog = {
        timestamp: new Date().toISOString(),
        requestId: requestId,
        type: 'request_finish',
        method: method,
        url: originalUrl,
        ip: ip,
        statusCode: res.statusCode,
        durationMs: duration,
        contentLength: res.get('content-length') || '-',
      };

      // 🎯 Envia o objeto JSON para o console/CloudWatch
      console.log(JSON.stringify(responseLog));
    });

    next();
  }
}
