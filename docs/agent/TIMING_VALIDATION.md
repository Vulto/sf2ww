# Timing and execution validation

The native C/OpenGL port is not a 68000 emulator. Host CPU cycles are therefore not an equivalence metric by themselves.

The pipeline measures two timing domains:

1. **Arcade execution time**: the CPS1 timing domain, using the 10 MHz main 68000 clock and the CPS1 video cadence.
2. **Host execution time**: monotonic nanoseconds spent executing one native game update, plus lateness against the next arcade deadline.

The CPS1 reference is 10 MHz for the main CPU. The video timing is 512 horizontal clocks x 262 scanlines at an 8 MHz pixel clock, approximately 59.6374 Hz, or 16.768 ms per frame. JTCPS documents the CPS-A CPU-speed field as 10 MHz/12 MHz and provides REPORT_DELAY timing in 48 MHz simulation ticks.

The native port records arcade_time_ns, arcade_cpu_cycles, host_logic_ns and host_start_late_ns. MAME records the same arcade-time axis from machine.time(), converted with attotime:as_ticks(10000000), and captures 68000 register state for diagnosis.

The comparison asks whether semantic state transitions occur at the same arcade-time/cycle positions. Host timing is a separate performance gate: the native update must complete inside its 16.768 ms budget without accumulating deadline misses.

References:
- https://docs.mamedev.org/luascript/
- https://docs.mamedev.org/techspecs/cpu_device.html
- https://github.com/mamedev/mame/blob/master/src/mame/capcom/cps1.cpp
- https://github.com/jotego/jtcps
