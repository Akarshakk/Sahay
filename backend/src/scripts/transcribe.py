#!/usr/bin/env python3
"""
Whisper Speech-to-Text Transcription Script
This script is called by the NestJS backend to transcribe audio files.

Requirements:
- pip install openai-whisper
- FFmpeg must be installed and in PATH
"""

import sys
import json
import whisper
import warnings

# Suppress FP16 warnings
warnings.filterwarnings("ignore", message="FP16 is not supported on CPU")

def transcribe_audio(audio_path: str, model_name: str = "base") -> dict:
    """
    Transcribe audio file using Whisper.
    
    Args:
        audio_path: Path to the audio file
        model_name: Whisper model to use (tiny, base, small, medium, large)
    
    Returns:
        Dictionary with transcription results
    """
    try:
        # Load the model (cached after first load)
        model = whisper.load_model(model_name)
        
        # Transcribe
        result = model.transcribe(
            audio_path,
            fp16=False,  # Use FP32 for CPU compatibility
            verbose=False
        )
        
        # Format segments for output
        segments = []
        if 'segments' in result:
            for seg in result['segments']:
                segments.append({
                    'start': round(seg['start'], 2),
                    'end': round(seg['end'], 2),
                    'text': seg['text'].strip()
                })
        
        return {
            'text': result['text'].strip(),
            'language': result.get('language', 'unknown'),
            'segments': segments
        }
        
    except Exception as e:
        return {
            'error': str(e),
            'text': '',
            'language': 'unknown',
            'segments': []
        }

def main():
    if len(sys.argv) < 2:
        print(json.dumps({'error': 'No audio file path provided', 'text': '', 'language': 'unknown', 'segments': []}))
        sys.exit(1)
    
    audio_path = sys.argv[1]
    model_name = sys.argv[2] if len(sys.argv) > 2 else "base"
    
    result = transcribe_audio(audio_path, model_name)
    print(json.dumps(result))

if __name__ == "__main__":
    main()
