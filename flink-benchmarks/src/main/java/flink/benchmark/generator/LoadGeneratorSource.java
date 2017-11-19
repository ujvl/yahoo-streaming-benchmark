package flink.benchmark.generator;

import org.apache.flink.streaming.api.functions.source.RichParallelSourceFunction;
import org.apache.flink.streaming.api.checkpoint.Checkpointed;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import java.util.List;
import java.util.Collections;

/**
 * Base class for LoadGenerator Sources.  Implements features to generate whatever load
 * you require.
 */
public abstract class LoadGeneratorSource<T> extends RichParallelSourceFunction<T>
                                             implements Checkpointed<Long> {

  private static final Logger LOG = LoggerFactory.getLogger(LoadGeneratorSource.class);

  private boolean running = true;

  private final int loadTargetHz;
  private final int timeSliceLengthMs;

  private long timeWindow;
  private long offset;

  public LoadGeneratorSource(int loadTargetHz, int timeSliceLengthMs) {
    this.loadTargetHz = loadTargetHz;
    this.timeSliceLengthMs = timeSliceLengthMs;
  }

  /**
   * Subclasses must override this to generate a data element
   */
  public abstract T generateElement(long timeWindow);


  /**
   * The main loop
   */
  @Override
  public void run(SourceContext<T> sourceContext) throws Exception {
    int elements = loadPerTimeslice();
    final Object lock = sourceContext.getCheckpointLock();
    if (timeWindow == 0)
      timeWindow = System.currentTimeMillis();
    while (running) {
      for (offset = 0; offset < elements; offset++) {
        synchronized (lock) {
          sourceContext.collect(generateElement(timeWindow));
        }
      }
      offset = 0;
      timeWindow += timeSliceLengthMs;
      // Sleep for the rest of timeslice if needed
      long emitTime = System.currentTimeMillis() - timeWindow + timeSliceLengthMs;
      if (emitTime < timeSliceLengthMs) {
        Thread.sleep(timeSliceLengthMs - emitTime);
        long timeToSpare = timeSliceLengthMs - emitTime;
        LOG.info((timeWindow - timeSliceLengthMs) + " TIME TO SPARE " + timeToSpare);
      } else {
        long behind = emitTime - timeSliceLengthMs;
        LOG.info((timeWindow - timeSliceLengthMs) + " FALLING BEHIND by " + behind);
      }
    }
    sourceContext.close();
  }

  @Override
  public void cancel() {
    running = false;
  }


  @Override
  public Long snapshotState(long checkpointId, long checkpointTimestamp) {
    return timeWindow;
  }

  @Override
  public void restoreState(Long state) {
    timeWindow = state;
  }

  /**
   * Given a desired load figure out how many elements to generate in each timeslice
   * before yielding for the rest of that timeslice
   */
  private int loadPerTimeslice() {
    int messagesPerOperator = loadTargetHz / getRuntimeContext().getNumberOfParallelSubtasks();
    return messagesPerOperator / (1000 / timeSliceLengthMs);
  }

}
