package funkin.util.macro;

using funkin.util.AnsiUtil;

#if !display
@:nullSafety
class GitCommit
{
  /**
   * Get the SHA1 hash of the current Git commit.
   */
  public static macro function getGitCommitHash():haxe.macro.Expr.ExprOf<String>
  {
    #if !display
    // Get the current line number.
    var pos = haxe.macro.Context.currentPos();

    var process = new sys.io.Process('git', ['rev-parse', 'HEAD']);

    var commitHash:String = "";
    if (process.exitCode() != 0)
    {
      var message = process.stderr.readAll().toString();
      haxe.macro.Context.info(' WARNING '.warning() + ' Could not determine current git commit; is this a proper Git repository?', pos);
    }
    else
    {
      // git succeeded but still produced no output; don't blow up on an empty stream.
      try
      {
        commitHash = process.stdout.readLine();
      }
      catch (e:Dynamic)
      {
        commitHash = "";
      }
    }

    var commitHashSplice:String = commitHash.substr(0, 7);

    process.close();

    // Generates a string expression
    return macro $v{commitHashSplice};
    #else
    // `#if display` is used for code completion. In this case returning an
    // empty string is good enough; We don't want to call git on every hint.
    var commitHashSplice:String = "";
    return macro $v{commitHashSplice};
    #end
  }

  /**
   * Get the branch name of the current Git commit.
   */
  public static macro function getGitBranch():haxe.macro.Expr.ExprOf<String>
  {
    #if !display
    // Get the current line number.
    var pos = haxe.macro.Context.currentPos();
    var branchProcess = new sys.io.Process('git', ['rev-parse', '--abbrev-ref', 'HEAD']);

    var branchName:String = "";
    if (branchProcess.exitCode() != 0)
    {
      var message = branchProcess.stderr.readAll().toString();
      haxe.macro.Context.info(' WARNING '.warning() + ' Could not determine current git commit; is this a proper Git repository?', pos);
    }
    else
    {
      try
      {
        branchName = branchProcess.stdout.readLine();
      }
      catch (e:Dynamic)
      {
        branchName = "";
      }
    }
    branchProcess.close();

    // Generates a string expression
    return macro $v{branchName};
    #else
    // `#if display` is used for code completion. In this case returning an
    // empty string is good enough; We don't want to call git on every hint.
    var branchName:String = "";
    return macro $v{branchName};
    #end
  }

  /**
   * Get whether the local Git repository is dirty or not.
   */
  public static macro function getGitHasLocalChanges():haxe.macro.Expr.ExprOf<Bool>
  {
    #if !display
    // Not a git checkout; there is nothing to diff, and running `git diff`
    // outside a repository just spams its usage text down a pipe we'd
    // otherwise have to drain. Bail out early instead.
    if (!sys.FileSystem.exists('.git'))
      return macro $v{false};

    // Git for Windows can emit one CRLF warning per changed source file.
    // Waiting for exit without draining stderr fills the pipe and deadlocks
    // the Haxe compiler. Suppress only that warning and always close the
    // process after collecting its exit code.
    var branchProcess = new sys.io.Process('git', ['-c', 'core.safecrlf=false', 'diff', '--quiet']);
    var exitCode:Int = branchProcess.exitCode(true);
    branchProcess.close();

    return macro $v{exitCode == 1};
    #else
    // `#if display` is used for code completion. In this case we just assume true.
    return macro $v{true};
    #end
  }
}
#end
