import java.io.*; // import all classes from the java.io package (which has the input/output functionality)
import java.util.*;

public class cachesim {

    static Scanner traceFileScanner;

    // struct describing an access from the trace file. Returned by `traceNextAccess`.
    private static class CacheAccess {
        boolean isStore;
        int address;
        int accessSize;
        byte[] data;
    }

    /**
     * opens a trace file, given its name. must be called before `traceNextAccess`,
     * which will begin reading from this file.
     * @param filename: the name of the trace file to open
     */
    public static void traceInit(String filename) {
        try {
            traceFileScanner = new Scanner(new File(filename));
        } catch (FileNotFoundException e) {
            System.err.println("Failed to open trace file: " + e.getMessage());
            System.exit(0);
        }
    }

    /**
     * closes the trace file scanner
     */
    public static void closeTraceFile() {
        if (traceFileScanner != null) {
            traceFileScanner.close();
        }
    }

    /**
     * checks if we've already read all accesses from the trace file.
     * @return true if the trace file is complete, false if there's more to read.
     */
    public static boolean traceFinished() {
        return !traceFileScanner.hasNextLine();
    }

    /**
     * read the next access in the trace. Errors if `traceFinished() == true`.
     * @return The access as a `cacheAccess` struct.
     */
    public static CacheAccess traceNextAccess() {
        String[] parts = traceFileScanner.nextLine().strip().split("\\s+");
        CacheAccess result = new CacheAccess();

        // parse address and access size
        result.address = Integer.parseInt(parts[1].substring(2), 16);
        result.accessSize = Integer.parseInt(parts[2]);

        // check access type
        if (parts[0].equals("store")) {
            result.isStore = true;

            // read data
            result.data = new byte[result.accessSize];
            for (int i = 0; i < result.accessSize; i++) {
                result.data[i] = (byte) Integer.parseInt(
                    parts[3].substring(i * 2, 2 + i * 2),
                    16
                );
            }
        } else if (parts[0].equals("load")) {
            result.isStore = false;
        } else {
            System.err.println("Invalid trace file access type" + parts[0]);
            System.exit(0);
        }
        return result;
    }

    // method for log2 calculation; i couldn't figure out how to use the one given in hw directions so I wrote my own!
    // custom logarithim base 2 calculation
    private static int log2(int n) {
        int r = -1;
        while (n > 0) {
            n >>= 1;
            r++;
        }
        return r;
    }

    public static class Frame { // each frame contains a valid bit, a dirty bit, a tag, and a data block 
        boolean valid;
        boolean dirty;
        int tag;
        byte[] data;

        // constructor for initialization
        public Frame(boolean valid, boolean dirty, int tag, byte[] data) {
            this.valid = valid;
            this.dirty = dirty;
            this.tag = tag;
            this.data = data;
        }
    }

        public static void main(String[] args) {
            // check that there are 4 command-line arguments
            if (args.length != 4) { 
                System.out.println("Usage: java CacheSimulator <trace-file> <cache-size-kB> <associativity> <block-size>");
                System.exit(0);
            }

            // parse the 4 command-line arguments
            String traceFile = args[0]; // filename of the memory access traace file
            int cacheSizeKB = Integer.parseInt(args[1]); // total capacity of the cache in kilobytes (kB). it's always a power of two between 1 and 2048
            int associativity = Integer.parseInt(args[2]); // the set associativity of the cache, AKA the number of ways. it's always a power of two
            int blockSize = Integer.parseInt(args[3]); // the size of the cache blocks in bytes. a power of two between 2 and 1024

            // calculate cache parameters
            int cacheSizeBytes = cacheSizeKB * 1024;
            int numSets = cacheSizeBytes / (associativity * blockSize); // number of sets in the cache

            // calculate offset, index, and tag bits
            int offsetBitsSize = log2(blockSize);
            int indexBitsSize = log2(numSets);

            // initialize cache as an ArrayList of LinkedLists (each set is a queue of frames)
            ArrayList<Queue<Frame>> cache = new ArrayList<>(numSets);
            for (int i = 0; i < numSets; i++) {
                cache.add(new LinkedList<Frame>());
            }

            // initialize memory
            byte[] memory = new byte[1 << 24];  // 16MB memory (1<<24 bytes)

            // initialize trace file reading with the provided trace functions
            traceInit(traceFile); // opens the actual trace file

            // process each trace access
            while (!traceFinished()) {
                CacheAccess access = traceNextAccess(); // read the next memory access from the trace
                int address = access.address;
                int accessSize = access.accessSize;

                // calculate the offset, index, and tag from the address
                int offset = address & ((1 << offsetBitsSize) - 1);
                int index = (address >> offsetBitsSize) & ((1 << indexBitsSize) - 1);
                int tag = address >> (offsetBitsSize + indexBitsSize);

                // create the set for the current index
                Queue<Frame> set = cache.get(index);

                // search for a hit (find the frame with matching tag and a valid bit)
                Frame frameHit = null;

                // search for a specific frame in the set
                for (Frame frame : set) {
                    if (frame.valid && frame.tag == tag) {
                        frameHit = frame;
                        break;
                    }
                }

                // handle the hit or miss
                if (frameHit != null) {

                    // cache hit 
                    // 1. for load hits, return the data from the cache
                    // 2. for store hits, update the cache block and mark as dirty
                    handleHit(access, frameHit, offset, accessSize);

                } else {
                    // cache miss
                    // 1. if the set is full, use FIFO
                    // 2. if the evicted frame is dirty, write it back to memory
                    // 3. load the required block from memory
                    // 4. for store misses, update the loaded block with the new data
                    handleMiss(address, access, set, memory, associativity, blockSize, offsetBitsSize, indexBitsSize, offset, index, tag);
                }
            }

            // close the trace file and exit
            closeTraceFile();
            System.exit(0);
        }

        // how to handle a miss
        private static void handleMiss(
                                        int address, 
                                        CacheAccess access, 
                                        Queue<Frame> set, 
                                        byte[] memory, 
                                        int associativity,  
                                        int blockSize, 
                                        int offsetBitsSize, 
                                        int indexBitsSize,
                                        int offset, 
                                        int index, 
                                        int tag){
                                        
            // FIFO eviction if the set is full
            if (set.size() >= associativity) { // check if cache set is full
                Frame evict = set.poll();  // evict a block; removes the oldest block (FIFO policy) from the set.

                if (evict != null && evict.valid) { // ensures the block evicted exists and is valid (contains meaningful data)
                    // print out the FIFO eviction info
                    int evictAddress = (evict.tag << (offsetBitsSize + indexBitsSize)) | (index << offsetBitsSize);
                    // shift tag to the left by the sum of offsetBitsSize and indexBitsSize OR
                    // shift index to the left by offsetBitsSize
                    // bitwise OR makes sure that that the tag occupies the higher-order bits, and the index occupies the correct position below it
                        System.out.printf("replacement 0x%s %s\n",
                        Integer.toHexString(evictAddress),
                        evict.dirty ? "dirty" : "clean"); // prints the memory address of the evicted block in hex, indicates whether block is dirty (modified) or clean (unmodified)

                    // if evict is dirty, write it back to memory 
                    if (evict.dirty) {
                        System.arraycopy(evict.data, 0, memory, evictAddress, blockSize);
                    }
                }
            }

            // calculate the block address for the miss
            int blockStartAddress = address & ~((1 << offsetBitsSize) - 1); 
            byte[] newData = new byte[blockSize];
            System.arraycopy(memory, blockStartAddress, newData, 0, blockSize); // compute and copy starting address of the block that contains access.address

            // create a new frame and load the data
            Frame newFrame = new Frame(true, access.isStore, tag, newData);

            // add new frame to the cache set
            set.offer(newFrame);

            // print miss info and handle the store/load
            if (access.isStore) { 
                System.out.printf("store 0x%s miss\n", Integer.toHexString(access.address)); // log a store miss and the hex address of the missed operation
                int end = (offset + access.accessSize < newFrame.data.length) ? offset + access.accessSize : newFrame.data.length;
                // prev line computes end (ie upper limit of range within the array newFrame data) and uses ternary operator so that calculated value stays within bounds of array
                System.arraycopy(access.data, 0, newFrame.data, offset, end - offset);
                // prev line copies access.data (the data being written) into newFrame.data starting at the offset position
                // only copies up to the computed end to avoid out-of-bounds errors amy!!!!
                newFrame.dirty = true; // marks cache block as dirty because it has been modified by the store op

            } else { // handle a load (read) miss
                System.out.printf("load 0x%s miss ", Integer.toHexString(access.address)); // logs a load miss and the hex address of the missed operation
                for (int i = offset; i < offset + access.accessSize; i++) { // iterates thru the relev portion of newFrame.data (starting at offset and covering access.accessSize bytes) and prints each byte as a two-character hexadecimal value.
                    System.out.printf("%02x", newFrame.data[i]);
                }
                System.out.println();
            }
        }

        // how to handle a hit
        private static void handleHit(CacheAccess access, Frame frameHit, int offset, int accessSize) {
            
            // handle store hit
            if (access.isStore) {
                System.out.printf("store 0x%s hit\n", Integer.toHexString(access.address));
                int end = (offset + accessSize < frameHit.data.length) ? offset + accessSize : frameHit.data.length; 
                // checks if sum of offset and accessSize is less than array's length, if true set end to offset + accessSize, if false set end to frameHit.data.length
                // prev line ensures that end does not exceed the valid bounds of the frameHit.data array
                // ie prevents an ArrayIndexOutOfBoundsException, uses ternary operator
                
                // copy store data into the cache frame
                System.arraycopy(access.data, 0, frameHit.data, offset, end - offset);
                
                // mark the frame as dirty bc it was modified
                frameHit.dirty = true;
                
            } else { // handle load hit
                System.out.printf("load 0x%s hit ", Integer.toHexString(access.address));
                for (int i = offset; i < offset + accessSize; i++) {
                    System.out.printf("%02x", frameHit.data[i]);
                }

                System.out.println();
            }
        }
    }
