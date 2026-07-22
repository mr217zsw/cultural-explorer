import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { IsOptional, IsString } from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { MnemonicService } from './mnemonic.service';

class RegenerateDto { @IsString() regionId!: string; @IsOptional() @IsString() style?: string; }

@Controller('mnemonic')
export class MnemonicController {
  constructor(private readonly mnemonic: MnemonicService) {}
  @Get(':regionId') get(@Param('regionId') regionId: string) { return this.mnemonic.getOrCreate(regionId); }
  @Post('regenerate') @UseGuards(JwtAuthGuard) regenerate(@Body() dto: RegenerateDto) { return this.mnemonic.generate(dto.regionId, dto.style ?? '七言口诀', true); }
  @Get('share/:regionId') share(@Param('regionId') regionId: string) { return this.mnemonic.share(regionId); }
}

