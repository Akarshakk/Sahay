import { Controller, Post, Delete, Param, Body, UploadedFile, UseInterceptors, BadRequestException, Query } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import * as fs from 'fs';

// Ensure directory exists
// Ensure directory exists
const uploadDir = join(process.cwd(), 'uploads', 'all_documents');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

@Controller('upload')
export class UploadController {
    @Post()
    @UseInterceptors(FileInterceptor('file', {
        storage: diskStorage({
            destination: (req, file, cb) => {
                const folder = (req.query.folder || 'all_documents').toString().replace(/[^a-zA-Z0-9_]/g, '');
                const uploadPath = join(process.cwd(), 'uploads', folder);
                if (!fs.existsSync(uploadPath)) {
                    fs.mkdirSync(uploadPath, { recursive: true });
                }
                cb(null, uploadPath);
            },
            filename: (req, file, cb) => {
                const username = (req.query.username || req.body?.username || 'user').toString().replace(/[^a-zA-Z0-9]/g, '_');
                const docType = (req.query.documentType || req.body?.documentType || 'document').toString();
                const timestamp = Date.now();
                const cleanName = `${username}_${docType}_${timestamp}${extname(file.originalname)}`;
                return cb(null, cleanName);
            },
        }),
        fileFilter: (req, file, cb) => {
            if (!file.originalname.match(/\.(jpg|jpeg|png|pdf)$/i)) {
                return cb(new BadRequestException('Only image files are allowed!'), false);
            }
            cb(null, true);
        },
        limits: { fileSize: 5 * 1024 * 1024 } // 5MB
    }))
    async uploadFile(
        @UploadedFile() file: Express.Multer.File,
        @Query('username') username?: string,
        @Query('documentType') documentType?: string,
        @Query('folder') folder?: string,
    ) {
        if (!file) {
            throw new BadRequestException('File is missing');
        }

        const safeFolder = (folder || 'all_documents').replace(/[^a-zA-Z0-9_]/g, '');

        return {
            url: `http://localhost:3000/uploads/${safeFolder}/${file.filename}`,
            filename: file.filename,
            originalName: file.originalname,
            documentType: documentType || 'document',
        };
    }

    @Delete(':filename')
    deleteFile(@Param('filename') filename: string) {
        const filePath = join(uploadDir, filename);

        if (!fs.existsSync(filePath)) {
            throw new BadRequestException('File not found');
        }

        try {
            fs.unlinkSync(filePath);
            return { success: true, message: 'File deleted successfully' };
        } catch (error) {
            throw new BadRequestException('Failed to delete file');
        }
    }
}
