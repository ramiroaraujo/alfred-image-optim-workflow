<?php
require_once "vendor/autoload.php";

/**
 * Class ImageOptimWorkflow
 */
class ImageOptimWorkflow
{
    /**
     *
     */
    const SOUND_NOTICE = 'Hero';
    /**
     *
     */
    const SOUND_SUCCESS = 'Glass';
    /**
     *
     */
    const SOUND_ERROR = 'Basso';
    /**
     *
     */
    const NOTIFICATION_TIME = 30;

    /**
     * @param $paths
     * @return bool|string
     */
    public function optimize($paths)
    {
        if ($this->checkCurrentPidRunning()) {
            $this->notify('Notice!', 'There\'s a previous optimization process running', 'imageoptim', self::SOUND_NOTICE);
            shell_exec('osascript -e \'tell application "Alfred 2" to search "optimize progress"\'');
            return false;
        }

        $files = $this->getAllImageFiles(explode("\t", $paths));
        if (empty($files)) {
            $this->notify('Woops', 'There\'re not image files in the selection', 'imageoptim', self::SOUND_ERROR);
            return false;
        }

        //log start time, base sizes and file scale
        $previous_notification = time();
        $old_sizes = 0;
        $new_sizes = 0;
        $scale = 'Kb';

        //persist current PID
        $this->createProcessFile(count($files));

        //optimize each file, recording filesize before and after optim
        foreach ($files as $index => $file) {
            $old_sizes += filesize($file);
            shell_exec("bin/image_optim --allow-lossy --no-pngout --no-svgo --jpegrecompress-method smallfry '{$file}'");
            clearstatcache(true, $file);
            $new_sizes += filesize($file);
            $current = $this->readProcessFile();
            $current->time = time();
            $current->done = $index + 1;
            $this->updateProcessFile($current);
            if (time() - $previous_notification > self::NOTIFICATION_TIME && $index < (count($files) - 1)) {
                if (!$current->mute) {
                    $previous_notification = time();
                    $this->notify('Optimizing images...', sprintf('%d out of %d done', $index + 1, count($files)), 'imageoptim');
                }
            }
        }

        //delete current PID reference file
        $this->deleteCurrentProcessFile();

        //convert bytes to Kilobytes
        $old_sizes /= 1024;
        $new_sizes /= 1024;

        //if total size was bigger than 5MB, convert Kilobytes to Megabytes
        if ($old_sizes > 1024 * 5) {
            $old_sizes /= 1024;
            $new_sizes /= 1024;
            $scale = 'Mb';
        }
        $percent = ($old_sizes - $new_sizes) / $old_sizes * 100;

        //return report
        return sprintf("Total was: %.2f%s now %.2f%s saving: %.2f%s (%.1f%%)", $old_sizes, $scale, $new_sizes, $scale, $old_sizes - $new_sizes, $scale, $percent);
    }

    /**
     * @param $paths
     * @return string
     */
    public function countFiles($paths)
    {
        if ($this->checkCurrentPidRunning()) {
            return false;
        }

        $files = $this->getAllImageFiles(explode("\t", $paths));
        if (empty($files)) {
            return false;
        }

        $count = count($files);
        return "Optimizing {$count} " . ($count < 2 ? 'Image' : 'Images');
    }

    /**
     *
     */
    public function muteCurrent()
    {
        if (!$this->checkCurrentPidRunning()) {
            return false;
        }
        $current = $this->readProcessFile();
        $current->mute = true;
        $this->updateProcessFile($current);
    }

    /**
     * @param $paths
     * @return mixed
     */
    private function getAllImageFiles($paths)
    {
        //generate a flat array of all viable files, direct files are added if they're images, and folders are scanned for images
        return array_reduce($paths, function ($paths, $path) {
            if (is_file($path)) {
                if (in_array(strtolower(pathinfo($path, PATHINFO_EXTENSION)), ['jpg', 'jpeg', 'png', 'gif'])) {
                    $paths[] = $path;
                }
                return $paths;
            } else {
                $glob = \Webmozart\Glob\Glob::glob("{$path}/{,**/}*.{jpg,jpeg,png,gif}");
                return array_merge($paths, $glob);
            }
        }, []);
    }

    /**
     * @return bool|mixed
     */
    public function getCurrentProcess()
    {
        if (!$this->checkCurrentPidRunning()) return false;
        return $this->readProcessFile();
    }

    /**
     *
     */
    public function cancelCurrent()
    {
        $process = $this->getCurrentProcess();
        posix_kill($process->pid, SIGKILL);
        $this->deleteCurrentProcessFile();
        $this->notify('Optimization Stopped', "Optimized {$process->done} out of {$process->total} images", 'imageoptim', self::SOUND_NOTICE);
    }

    /**
     * @return bool
     */
    private function checkCurrentPidRunning()
    {
        if (!$this->checkCurrentProcessFile()) return false;

        $process = $this->readProcessFile();

        //check if the process is still running
        if (shell_exec("ps -A | perl -ne 'print if /^\\s*{$process->pid}/' | wc -l") == 0) {
            $this->deleteCurrentProcessFile();
            return false;
        }
        return true;
    }

    /**
     * @return bool
     */
    private function checkCurrentProcessFile()
    {
        return file_exists('.current');
    }

    /**
     *
     */
    private function createProcessFile($total)
    {
        if ($this->checkCurrentProcessFile()) $this->deleteCurrentProcessFile();
        $data = (object)['pid' => getmypid(), 'mute' => false, 'total' => $total, 'done' => 0, 'start' => time()];
        file_put_contents('.current', json_encode($data));
        return $data;
    }

    /**
     * @param $data
     */
    private function updateProcessFile($data)
    {
        $this->deleteCurrentProcessFile();
        file_put_contents('.current', json_encode($data));
    }

    /**
     * @return bool|mixed
     */
    private function readProcessFile()
    {
        if (!$this->checkCurrentProcessFile()) return false;
        return json_decode(file_get_contents('.current'));
    }

    /**
     *
     */
    private function deleteCurrentProcessFile()
    {
        unlink('.current');
    }

    /**
     * @param $title
     * @param $message
     * @param string $id
     * @param bool|false $sound
     */
    private function notify($title, $message, $id = 'workflow', $sound = false)
    {
        $sound = !$sound ? '' : "-sound {$sound}";
        $icon = realpath('./icon.png');
        shell_exec("./bin/terminal-notifier.app/Contents/MacOS/terminal-notifier -title \"{$title}\" -message \"{$message}\" -group {$id} {$sound} -sender com.runningwithcrayons.Alfred-2 -contentImage \"{$icon}\"");
    }
}
