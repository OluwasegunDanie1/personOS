import 'reflect-metadata';
import { config as loadEnvironment } from 'dotenv';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { ResponseInterceptor } from './common/http/response.interceptor';
import { GlobalExceptionFilter } from './common/http/global-exception.filter';
import { getTrustProxySetting } from './security/trust-proxy.config';

// Loads backend/.env into process.env before any module reads it. Silent
// no-op in production, where secrets come from the deployment environment
// and no .env file is committed; never overrides already-set values.
loadEnvironment({ quiet: true });

async function bootstrap(): Promise<void> {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  app.setGlobalPrefix('api/v1');
  app.useGlobalInterceptors(new ResponseInterceptor());
  app.useGlobalFilters(new GlobalExceptionFilter());
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const trustProxySetting = getTrustProxySetting();
  if (trustProxySetting !== false) {
    app.set('trust proxy', trustProxySetting);
  }

  // Local development fallback only; production environments must set PORT explicitly.
  const port = process.env.PORT ?? 3000;

  await app.listen(port);
}

bootstrap();
