import {
  Controller,
  Post,
  UseInterceptors,
  UploadedFile,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { existsSync, mkdirSync, unlinkSync } from 'fs';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

// Ensure uploads directory exists
const uploadsDir = join(__dirname, '..', '..', '..', 'uploads', 'audio');
if (!existsSync(uploadsDir)) {
  mkdirSync(uploadsDir, { recursive: true });
}

@Controller('transcription')
export class TranscriptionController {
  
  @Post('speech-to-text')
  @UseInterceptors(
    FileInterceptor('audio', {
      storage: diskStorage({
        destination: uploadsDir,
        filename: (req, file, callback) => {
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
          callback(null, `audio-${uniqueSuffix}${extname(file.originalname)}`);
        },
      }),
      fileFilter: (req, file, callback) => {
        const allowedMimes = [
          'audio/wav',
          'audio/wave',
          'audio/x-wav',
          'audio/mpeg',
          'audio/mp3',
          'audio/mp4',
          'audio/m4a',
          'audio/x-m4a',
          'audio/ogg',
          'audio/flac',
          'audio/webm',
        ];
        if (allowedMimes.includes(file.mimetype) || file.originalname.match(/\.(wav|mp3|m4a|ogg|flac|webm)$/i)) {
          callback(null, true);
        } else {
          callback(new HttpException('Invalid audio file type', HttpStatus.BAD_REQUEST), false);
        }
      },
      limits: {
        fileSize: 25 * 1024 * 1024, // 25MB max
      },
    }),
  )
  async transcribeAudio(@UploadedFile() file: Express.Multer.File) {
    if (!file) {
      throw new HttpException('No audio file provided', HttpStatus.BAD_REQUEST);
    }

    try {
      // Call Python Whisper script
      const result = await this.runWhisperTranscription(file.path);
      
      // Cleanup the uploaded file
      try {
        unlinkSync(file.path);
      } catch (e) {
        console.error('Failed to cleanup audio file:', e);
      }

      return {
        success: true,
        data: {
          text: result.text,
          language: result.language,
          segments: result.segments,
        },
      };
    } catch (error) {
      // Cleanup on error
      try {
        unlinkSync(file.path);
      } catch (e) {
        // Ignore cleanup errors
      }
      
      console.error('Transcription error:', error);
      throw new HttpException(
        `Transcription failed: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }

  private async runWhisperTranscription(audioPath: string): Promise<{
    text: string;
    language: string;
    segments: any[];
  }> {
    const scriptPath = join(__dirname, '..', '..', 'scripts', 'transcribe.py');
    
    try {
      // Run Python script with Whisper
      const { stdout, stderr } = await execAsync(
        `python3 "${scriptPath}" "${audioPath}"`,
        { timeout: 120000 } // 2 minute timeout
      );

      if (stderr && !stderr.includes('FP16')) {
        console.warn('Whisper stderr:', stderr);
      }

      const result = JSON.parse(stdout);
      return result;
    } catch (error) {
      console.error('Whisper execution error:', error);
      
      // Fallback: Return empty result if Whisper is not available
      // In production, you'd want to handle this properly
      throw new Error('Speech recognition service unavailable. Please try again later.');
    }
  }
}
