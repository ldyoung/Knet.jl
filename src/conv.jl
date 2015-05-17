# TODO: generalize to N-D
# TODO: cpu implementation
# TODO: get rid of Float32
# TODO: add ConvolutionDescriptor if needed
# TODO: add xavier init

type Conv <: Layer; w::Param; x; y; dx; dy; Conv()=new(); end
Conv(w::Param)=(l=Conv();l.w=w;l)
Conv(w; a...)=Conv(Param(w; a...))
Conv(d::Integer...; a...)=Conv(Param(randn(d)*0.01; a...))

update(l::Conv)=update(l.w)
setparam!(l::Conv; a...)=setparam!(l.w; a...)
forw(l::Conv, x; o...)=error("CPU conv not implemented")
back(l::Conv, dy; o...)=error("CPU conv not implemented")

if GPU

function forw(l::Conv, x::CudaArray; o...)
    initforw(l, x)
    cudnnConvolutionForward(l.x, l.w.data, l.y)
end

function initforw(l::Conv, x::CudaArray)
    l.x = x
    chksize(l, :y, l.x, cudnnGetConvolutionNdForwardOutputDim(l.x, l.w.data))
end

function back(l::Conv, dy::CudaArray; dx=true, o...)
    initback(l, dy, dx)
    cudnnConvolutionBackwardFilter(l.x, l.dy, l.w.diff)
    dx && cudnnConvolutionBackwardData(l.w.data, l.dy, l.dx)
end

function initback(l::Conv, dy::CudaArray, dx)
    if (size(dy) == size(l.y))
        l.dy = dy
    else
        @assert length(dy) == length(l.y)
        l.dy = reshape(dy, size(l.y))
    end
    chksize(l.w, :diff, l.w.data)
    dx && chksize(l, :dx, l.x)
end

end # if GPU

