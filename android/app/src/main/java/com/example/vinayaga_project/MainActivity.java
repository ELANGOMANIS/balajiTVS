import android.os.Bundle;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;
import java.io.BufferedReader;
import java.io.InputStreamReader;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "backup_channel";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("executeBackupScript")) {
                                executeBackupScript(result);
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private void executeBackupScript(MethodChannel.Result result) {
        try {
            Process process = Runtime.getRuntime().exec("\"C:\\scripts\\backup_script.sh\"");
            //Process process = Runtime.getRuntime().exec("/path/to/your/backup_script.bat"); // Replace with the path to your backup script
            int exitCode = process.waitFor();
            if (exitCode == 0) {
                result.success("Database backup successful");
            } else {
                result.error("BACKUP_ERROR", "Database backup failed", null);
            }
        } catch (Exception e) {
            result.error("BACKUP_ERROR", e.getMessage(), null);
        }
    }
}
