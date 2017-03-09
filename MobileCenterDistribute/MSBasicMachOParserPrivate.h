@interface MSBasicMachOParser ()

/**
 *  (For testing only) Read data if length size to buffer from file fh.
 *
 *  @param fh      file from which to read data.
 *  @param buffer  output buffer where to write data
 *  @param size    number of bytes to read
 *
 *  @return A service with common logic already implemented.
 */
- (BOOL)readDataFromFile:(NSFileHandle *)fh toBuffer:(void *)buffer ofLength:(NSUInteger)size;
@end

