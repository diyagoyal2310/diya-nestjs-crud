import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { ArticlesService } from './articles.service';

describe('Articles', () => {
  let provider: ArticlesService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ArticlesService,
        {
          provide: getModelToken('Article'),
          useValue: {
            deleteOne: jest.fn(),
            find: jest.fn(),
            findById: jest.fn(),
          },
        },
      ],
    }).compile();

    provider = module.get<ArticlesService>(ArticlesService);
  });

  it('should be defined', () => {
    expect(provider).toBeDefined();
  });
});
