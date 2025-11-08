import * as path from 'path';
import { FILE_CONSTRAINTS } from '../constants';
import { ValidationResult } from '../types';

/**
 * ファイル拡張子を取得
 */
export const getFileExtension = (filename: string): string => {
  return path.extname(filename).toLowerCase();
};

/**
 * ファイル名（拡張子なし）を取得
 */
export const getFileNameWithoutExtension = (filename: string): string => {
  return path.basename(filename, path.extname(filename));
};

/**
 * ファイルサイズを人間が読みやすい形式に変換
 */
export const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
};

/**
 * ファイル形式の検証
 */
export const validateFileType = (filename: string, type: 'rules' | 'source'): ValidationResult => {
  const extension = getFileExtension(filename);
  const allowedExtensions = type === 'rules' 
    ? FILE_CONSTRAINTS.ALLOWED_RULE_EXTENSIONS
    : FILE_CONSTRAINTS.ALLOWED_SOURCE_EXTENSIONS;
  
  const isValid = allowedExtensions.includes(extension);
  
  return {
    isValid,
    errors: isValid ? [] : [`対応していないファイル形式です: ${extension}`],
    warnings: []
  };
};

/**
 * ファイルサイズの検証
 */
export const validateFileSize = (size: number): ValidationResult => {
  const isValid = size <= FILE_CONSTRAINTS.MAX_FILE_SIZE;
  
  return {
    isValid,
    errors: isValid ? [] : [`ファイルサイズが制限を超えています: ${formatFileSize(size)}`],
    warnings: size > FILE_CONSTRAINTS.MAX_FILE_SIZE * 0.8 ? 
      ['ファイルサイズが大きいため、処理に時間がかかる可能性があります'] : []
  };
};

/**
 * 安全なファイル名の生成
 */
export const sanitizeFileName = (filename: string): string => {
  // 危険な文字を除去
  return filename.replace(/[<>:"/\\|?*]/g, '_').replace(/\s+/g, '_');
};

/**
 * 一意なファイル名の生成
 */
export const generateUniqueFileName = (baseName: string, extension: string): string => {
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  return `${sanitizeFileName(baseName)}_${timestamp}${extension}`;
};

/**
 * クロスプラットフォーム対応のパス結合
 */
export const joinPath = (...segments: string[]): string => {
  return path.join(...segments);
};

/**
 * 相対パスを絶対パスに変換
 */
export const resolvePath = (relativePath: string): string => {
  return path.resolve(relativePath);
};