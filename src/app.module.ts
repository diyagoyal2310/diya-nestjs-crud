import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { ArticlesModule } from './articles/articles.module';
import 'dotenv/config';

const mongoUri = process.env.MONGODB_URI;

if (!mongoUri) {
  throw new Error('MONGODB_URI is not defined in the .env file');
}

@Module({
  imports: [
    MongooseModule.forRoot(mongoUri),
    ArticlesModule,
  ],
})
export class AppModule {}