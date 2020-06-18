module TLA

using Pkg.Artifacts
artifact_toml = joinpath(@__DIR__, "Artifacts.toml")
tla2tools_hash = artifact_hash("tla2tools", artifact_toml)

if tla2tools_hash == nothing || !artifact_exists(tla2tools_hash)
    tla2tools_hash = create_artifact() do artifact_dir
        tla2tools_url_base = "https://tla.msr-inria.inria.fr/tlatoolbox/dist/tla2tools.jar"
        download(
            "$(tla2tools_url_base)",
            joinpath(artifact_dir, "tla2tools.jar"),
        )
    end

    bind_artifact!(artifact_toml, "tla2tools", tla2tools_hash)
end

tla2tools_path = artifact"tla2tools"
tla2tools = tla2tools_path * "/tla2tools.jar"

function pcal(str)
    io = IOBuffer(str)
    run(pipeline(`java -cp $tla2tools pcal.trans $io`))
end

function pcal(str)
    try
        rm("test.tla")
    catch
    end
    io = open("test.tla", "w+")
    write(io, str)
    close(io)
    run(pipeline(`java -cp $tla2tools pcal.trans test.tla`))
    rm("test.tla")
end
pcal2(test)

tlc(str; default_ops = "-XX:+IgnoreUnrecognizedVMOptions - XX:+UseParallelGC") =
    run(`java $default_ops -cp $tla2tools tlc2.TLC $str`)
sany(str) = run(`java -cp $tla2tools tla2sany.SANY $str`)
tlatex(str) = run(`java -cp $tla2tools tla2tex.TLA $str`)

# use \bigvee<TAB> == ⋁ and \bigwedge<TAB> == ⋀
const unicode_dict = Dict(
    "∈" => raw"\in",
    "∀" => raw"\A",
    "∃" => raw"\E",
    "⋀" => raw"/\\",
    "⋁" => raw"\/",
)
#remove_unicode(str) = replace(str, r"∈|∀|∃|⋀|⋁" => unicode_dict[])
function replace_unicode(str)
    str = replace(str, "∈" => raw"\in")
    str = replace(str, '∀' => raw"\A")
    str = replace(str, '∃' => raw"\E")
    str = replace(str, '⋀' => raw"/\\")
    str = replace(str, '⋁' => raw"\/")
    str = replace(str, '↦' => "|->")
    str = replace(str, '⋃' => raw"\union")
    str = replace(str, '⋂' => raw"\intersect")
    str = replace(str, '∉' => raw"\notin")
    str = replace(str, '⟨' => "<<")
    str = replace(str, '⟩' => ">>")
    str = replace(str, '¬' => '~')
    str = replace(str, '⊆' => raw"\subseteq")
    str = replace(str, '≠' => "/=")
    str
end

replace_unicode("yow")

test = """
EXTENDS Integers
(*--algorithm wire
    variables
        people = {"alice", "bob"},
        acc = [alice |-> 5, bob |-> 5];
begin
    skip;
end algorithm;*)
"""

replace_unicode(test) |> pcal

end
