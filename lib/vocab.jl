SOS = "<sos>" # start of sentence token
EOS = "<eos>" # end of sentence token
UNK = "<unk>" # token for unknown words
PAD = "<pad>" # padding token

type Vocabulary
    counts # word counts dict
    sorted # sorted word counts tuple, for stats
    w2i # word to index dict
    i2w # index to word array
    size # vocabulary size, total different words count
    min_occur # minimum occurence

    function Vocabulary(words::Array{Any,1}, min_occur)
        # get word counts
        counts = Dict()
        for word in words
            if haskey(counts, word)
                counts[word] += 1
            else
                counts[word] = 1
            end
        end

        # filter less occured words, build word2index dict upon that collection
        counts = filter((w,o) -> o >= min_occur , counts)
        sorted = sort(collect(counts), by = tuple -> last(tuple), rev=true)
        w2i = Dict(SOS => 1)

        i = 2
        for (w,o) in sorted
            w2i[w] = i
            i += 1
        end

        w2i[EOS] = i
        w2i[UNK] = i+1
        w2i[PAD] = i+2

        # build index2word array
        vocabsize = length(values(w2i))
        i2w = map(j -> "", zeros(vocabsize))
        for (k,v) in w2i
            i2w[v] = k
        end

        new(counts, sorted, w2i, i2w, vocabsize, min_occur)
    end
end

atype = Float32
word2index(voc::Vocabulary, w) = haskey(voc.w2i, w) ? voc.w2i[w] : voc.w2i[UNK]
index2word(voc::Vocabulary, i) = voc.i2w[i]
most_occurs(voc::Vocabulary, N) = map(x -> (x.first, y.first), voc.sorted[1:N])
word2onehot(voc::Vocabulary, w) = (v = zeros(atype,voc.size,1); v[word2index(voc, w)] = 1; v)
sen2vec(voc::Vocabulary, s) = mapreduce(w -> word2index(voc, w), vcat, vcat(SOS, s, EOS))
word2svec(voc::Vocabulary, w) = (v = map(atype,spzeros(voc.size,1)); v[word2index(voc, w)] = 1; v)
sen2smat(voc::Vocabulary, s) = mapreduce(w -> word2svec(voc, w), hcat, [SOS;s;EOS])
vec2sen(voc::Vocabulary, vec) = join(map(i -> index2word(voc,i), vec[2:end-1]), " ")
