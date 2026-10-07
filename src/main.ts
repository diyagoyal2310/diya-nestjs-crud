import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { HttpExceptionFilter } from './filters/http-exception.filter';
import { JWTGuard } from './guards/jwt.guard';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalFilters(new HttpExceptionFilter());
  app.useGlobalGuards(app.get(JWTGuard));

  const options= new DocumentBuilder()
    .setTitle('Articles')
    .setDescription('Simple CRUD for managing articles')
    .setVersion('1.0')
    .addTag('articles')
    .addApiKey(
      {
        type: 'apiKey',
        in: 'header',
        name: 'x-jwt-assertion',
        description: 'Signed JWT returned by POST /auth/login',
      },
      'jwt-assertion',
    )
    .build();

  const document = SwaggerModule.createDocument(app, options);
  SwaggerModule.setup('docs', app, document);

  await app.listen(3000, '0.0.0.0');
}

bootstrap();

