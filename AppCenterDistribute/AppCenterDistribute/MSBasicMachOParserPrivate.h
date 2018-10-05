@interface MSBasicMachOParser ()

/**
 * (For testing only) Read data if length size to buffer from file fh.
 *
 * @param fh      File from which to read data.
 * @param buffer  Output buffer where to write data.
 * @param size    Number of bytes to read.
 *
 * @return `YES` if read succeeded else `NO`.
 */
- (BOOL)readDataFromFile:(NSFileHandle *)fh toBuffer:(void *)buffer ofLength:(NSUInteger)size;

@end
