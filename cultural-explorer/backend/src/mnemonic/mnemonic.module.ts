import { Module } from '@nestjs/common';
import { MnemonicController } from './mnemonic.controller';
import { MnemonicService } from './mnemonic.service';

@Module({ controllers: [MnemonicController], providers: [MnemonicService] })
export class MnemonicModule {}
