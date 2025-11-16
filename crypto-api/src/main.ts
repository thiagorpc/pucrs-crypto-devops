import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  const configService = app.get(ConfigService);
  const port = configService.get<number>('PORT', 3000);
  const host = configService.get<string>('HOST', 'localhost');

  const allowedOrigins = configService.get<string>(
    'CORS_ORIGIN',
    'http://localhost:5173',
  );

  app.enableCors({
    origin: allowedOrigins,
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
  });

  await app.listen(port, host);

  const logger = new Logger('Bootstrap');

  logger.log(`🚀 API... rodando em http://${host}:${port}`);
  logger.log(`🚀 Permitido CORS: ${allowedOrigins.toString()}`);
}

void bootstrap();
