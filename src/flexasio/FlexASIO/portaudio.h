#pragma once

#include <portaudio.h>

#include <memory>
#include <stdexcept>
#include <string>

namespace flexasio {

	struct StreamParameters final {
		PaStreamParameters* inputParameters;
		PaStreamParameters* outputParameters;
		double sampleRate;
	};

	// KoordASIO addition: carries the PortAudio error code so CreateBuffers can
	// recognize a rejected sample rate without parsing message text.
	class PortAudioException : public std::runtime_error {
	public:
		PortAudioException(PaError error, const std::string& message) : std::runtime_error(message), error(error) {}
		PaError GetError() const { return error; }

	private:
		PaError error;
	};

	void CheckFormatSupported(const StreamParameters&);

	struct StreamDeleter {
		void operator()(PaStream*) throw();
	};
	using Stream = std::unique_ptr<PaStream, StreamDeleter>;
	Stream OpenStream(const StreamParameters&, unsigned long framesPerBuffer, PaStreamFlags streamFlags, PaStreamCallback *streamCallback, void *userData);

	struct StreamStopper {
		void operator()(PaStream*) throw();
	};
	using ActiveStream = std::unique_ptr<PaStream, StreamStopper>;
	ActiveStream StartStream(PaStream*);

}
