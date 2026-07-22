import {
  Controller,
  Post,
  UploadedFile,
  UseInterceptors,
  UseGuards,
  Query,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { StorageService } from '../common/storage.service';

@Controller('upload')
export class UploadController {
  constructor(private readonly storage: StorageService) {}

  @Post('image')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 10 * 1024 * 1024 } }))
  async uploadImage(@UploadedFile() file: Express.Multer.File, @Query('folder') folder = 'images') {
    const url = await this.storage.uploadImage(file.buffer, file.originalname, folder);
    return { url };
  }

  @Post('audio')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file', { limits: { fileSize: 20 * 1024 * 1024 } }))
  async uploadAudio(@UploadedFile() file: Express.Multer.File, @Query('folder') folder = 'audio') {
    const url = await this.storage.uploadAudio(file.buffer, file.originalname, folder);
    return { url };
  }
}
