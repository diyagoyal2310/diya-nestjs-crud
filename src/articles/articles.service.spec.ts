import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { ArticlesService } from './articles.service';

describe('Articles', () => {
  let provider: ArticlesService;

  beforeEach(async () => {
    const mockArticleModel: any = jest.fn().mockImplementation(() => ({
      save: jest.fn(),
    }));

    mockArticleModel.deleteOne = jest.fn();
    mockArticleModel.find = jest.fn().mockReturnValue({
      select: jest.fn().mockReturnThis(),
      exec: jest.fn(),
    });
    mockArticleModel.findById = jest.fn().mockReturnValue({
      exec: jest.fn(),
    });

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ArticlesService,
        {
          provide: getModelToken('Article'),
          useValue: mockArticleModel,
        },
      ],
    }).compile();

    provider = module.get<ArticlesService>(ArticlesService);
  });

  it('should be defined', () => {
    expect(provider).toBeDefined();
  });
});
