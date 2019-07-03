#include "nstcommon.h"
#include "config.h"
#include "audio.h"

#include <AudioToolbox/AudioFile.h>
#include <AudioToolbox/AudioQueue.h>
#include <AudioToolbox/AudioFormat.h>

static AudioQueueRef                   queue = 0;
static AudioQueueBufferRef             buffers[2] = {0,0};

static int16_t audiobuf[6400];
static int framerate, channels, bufsize;
extern Emulator emulator;
static bool paused = false;

static std::vector<AudioQueueBufferRef> empty_buffers;

static void audio_buffer_callback(void *                 inUserData,
                             AudioQueueRef           queue,
                             AudioQueueBufferRef     buffer) {
    empty_buffers.push_back(buffer);
}
static void schedule_buffer(AudioQueueBufferRef buffer) {
    UInt32 numBytes = buffer->mAudioDataBytesCapacity;
    if (numBytes > bufsize) {
        numBytes = bufsize;
    }
    buffer->mAudioDataByteSize = numBytes;
    memcpy(buffer->mAudioData, audiobuf, numBytes);
    AudioQueueEnqueueBuffer(queue,
                            buffer,
                            0,
                            0);
}
void audio_init() {
    
    // Set the framerate based on the region. For PAL: (60 / 6) * 5 = 50
    framerate = nst_pal() ? (conf.timing_speed / 6) * 5 : conf.timing_speed;
    channels = conf.audio_stereo ? 2 : 1;
    bufsize = 2 * channels * (conf.audio_sample_rate / framerate);
    
    memset(audiobuf, 0, sizeof(audiobuf));
    
    AudioStreamBasicDescription data_format;
    data_format.mSampleRate = conf.audio_sample_rate;
    data_format.mFormatID = kAudioFormatLinearPCM;
    data_format.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    data_format.mBytesPerFrame = 2 * channels;
    data_format.mChannelsPerFrame = channels;
    data_format.mBitsPerChannel = 16;
    
    data_format.mBytesPerPacket = data_format.mBytesPerFrame;
    data_format.mFramesPerPacket = 1;
    data_format.mReserved = 0;
    
    
    OSStatus result = AudioQueueNewOutput(&data_format,
                                          &audio_buffer_callback, 0,
                                          CFRunLoopGetCurrent(), kCFRunLoopCommonModes,
                                          0, &queue);
    if (result != noErr) {
        printf("AudioQueueNewOutput failed: %d\n",result);
    }
    if (queue) {
        result = AudioQueueAllocateBuffer(queue, sizeof(audiobuf), &buffers[0]);
        result = AudioQueueAllocateBuffer(queue, sizeof(audiobuf), &buffers[1]);
        schedule_buffer(buffers[0]);
        schedule_buffer(buffers[1]);
        result = AudioQueueStart(queue,0);
        if (result != noErr) {
            printf("AudioQueueStart failed: %d\n",result);
        }
    }
}

void audio_deinit() {
    if (queue) {
        AudioQueueDispose(queue,true);
        queue = 0;
    }
}

void audio_play() {
    if (paused) { return; }
    bufsize = 2 * channels * (conf.audio_sample_rate / framerate);
    if (!empty_buffers.empty()) {
        AudioQueueBufferRef buffer = empty_buffers.front();
        empty_buffers.erase(empty_buffers.begin());
        schedule_buffer(buffer);
    }
}

void audio_pause() {
    // Pause the SDL audio device
    AudioQueuePause(queue);
    paused = true;
}
void audio_unpause() {
    // Unpause the SDL audio device
    AudioQueueStart(queue, 0);
    paused = false;
}
void audio_set_params(Sound::Output *soundoutput) {
    // Set audio parameters
    Sound sound(emulator);
    
    sound.SetSampleBits(16);
    sound.SetSampleRate(conf.audio_sample_rate);
    
    sound.SetSpeaker(conf.audio_stereo ? Sound::SPEAKER_STEREO : Sound::SPEAKER_MONO);
    sound.SetSpeed(Sound::DEFAULT_SPEED);
    
    audio_adj_volume();
    
    soundoutput->samples[0] = audiobuf;
    soundoutput->length[0] = conf.audio_sample_rate / framerate;
    soundoutput->samples[1] = NULL;
    soundoutput->length[1] = 0;
}
void audio_adj_volume() {
    // Adjust the audio volume to the current settings
    Sound sound(emulator);
    sound.SetVolume(Sound::ALL_CHANNELS, conf.audio_volume);
    sound.SetVolume(Sound::CHANNEL_SQUARE1, conf.audio_vol_sq1);
    sound.SetVolume(Sound::CHANNEL_SQUARE2, conf.audio_vol_sq2);
    sound.SetVolume(Sound::CHANNEL_TRIANGLE, conf.audio_vol_tri);
    sound.SetVolume(Sound::CHANNEL_NOISE, conf.audio_vol_noise);
    sound.SetVolume(Sound::CHANNEL_DPCM, conf.audio_vol_dpcm);
    sound.SetVolume(Sound::CHANNEL_FDS, conf.audio_vol_fds);
    sound.SetVolume(Sound::CHANNEL_MMC5, conf.audio_vol_mmc5);
    sound.SetVolume(Sound::CHANNEL_VRC6, conf.audio_vol_vrc6);
    sound.SetVolume(Sound::CHANNEL_VRC7, conf.audio_vol_vrc7);
    sound.SetVolume(Sound::CHANNEL_N163, conf.audio_vol_n163);
    sound.SetVolume(Sound::CHANNEL_S5B, conf.audio_vol_s5b);
    
    if (conf.audio_volume == 0) { memset(audiobuf, 0, sizeof(audiobuf)); }
}


