# Usage - timelapse.sh

    ./timelapse.sh [comand] [command] [...]

# Commands
 * using - Next parameter specifies configuration file (default: timelapse.cfg)
 * configure - Configure the timelapse
 * paths - Change the paths for temporary / output files
 * frames - process the source frames
 * master - render the master video
 * render - transcode the final videos from the master
 * rmtmp - remove temporary folder
 * full-reset - remove temporary folder and output folder
 * all - runs "configure frames master render rmtmp"

Only 'configure' and 'paths' require user interaction.

# Typical usage

    ./timelapse.sh configure frames master render

This configures the timelapse, processes the frames, renders the master video,
then transcodes it to the target sizes/bitrates

# Configuration

This is stored in the configuration file.  The default file if none is specified
via the `using` clause is `timelapse.cfg`.  The file is plain-text key=value
format and will be created if it does not exist already.

# Example

If I want two separate configurations, one for the original timelapse and one
for the noise-reduced one:

    ./timelapse.sh using timelapse-orig.cfg configure paths frames

1. This configures the first timelapse and stores the configuration to
`timelapse-orig`.

2. It also configures the paths for temporary and output files, so we can share the
same temporary folder as the denoised timelapse, but avoid overwriting the
output from it.

3. It then processes the frames, scaling and watermarking as needed.

    ./timelapse.sh using timelapse-nr.cfg configure paths

1. This configures the second timelapse, storing the configuration to
`timelapse-nr.cfg`.  We specify our noise-reduction filters via the
`Extra FFMPEG options for master render` option when asked.

2. It configures the paths, so we can share the same temporary folder as the
first timelapse but output to a different folder.

3. We don't need to specify the 'frames' command, since this generates temporary
files that are shared by the first timelapse.

    ./timelapse.sh using timelapse-orig.cfg master render
    ./timelapse.sh using timelapse-nr.cfg master render

Masters and renders each timelapse, using the same pre-processed temporary files
for both, but writing the outputs to two separate folders.

